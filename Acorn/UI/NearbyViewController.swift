//
//  NearbyViewController.swift
//  Acorn
//
//  Created by Jeremy Ling on 20/6/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import UIKit
import SearchTextField
import RSSelectionMenu
import CoreLocation

class NearbyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var filterButton: UIBarButtonItem!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBackgroundView: UIView!
    @IBOutlet weak var searchTextField: SearchTextField!
    @IBOutlet weak var locationBackgroundView: UIView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    let defaults = UserDefaults.standard
    lazy var nightModeOn = defaults.bool(forKey: "nightModePref")
    var textColor: UIColor?
    
    var nearbyList = [Article]()
    var filteredNearbyList = [Article]()
    
    let themeArray = ResourcesDay.THEME_LIST
    var selectedThemes = [String]()
    
    var mrtStationMap = [String: [String: Any]]()
    var mrtStationNames = [String]()
    var filteredStationNames = [String]()
    var selectedMrtStation: String?
    var locale: String?
    
    let dataSource = DataSource.instance
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let locale = locale {
            self.dataSource.getMrtStations { (stations) in
                self.mrtStationMap = stations
                self.searchNearbyArticles(station: locale)
            }
        } else {
            locationManager.requestWhenInUseAuthorization()
            if CLLocationManager.locationServicesEnabled() {
                print("locations enabled")
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.startUpdatingLocation()
            }
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 143
        
        self.dataSource.getMrtStations { (stations) in
            self.mrtStationMap = stations
            self.mrtStationNames = Array(stations.keys).sorted()
            self.searchTextField.filterStrings(self.mrtStationNames)
        }
        
//        searchTextField.userStoppedTypingHandler = {
//            self.filteredStationNames.removeAll()
//            for station in self.mrtStationNames {
//                if station.lowercased().contains((self.searchTextField.text ?? "").lowercased()) {
//                    self.filteredStationNames.append(station)
//                }
//            }
//            self.searchTextField.filterStrings(self.filteredStationNames)
//        }
        
        searchTextField.itemSelectionHandler = { filteredResults, itemPosition in
            let item = filteredResults[itemPosition]
            self.searchNearbyArticles(station: item.title)
        }
        
        self.filteredNearbyList = self.nearbyList
        
        searchBar.delegate = self
        
        let backSwipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(didSwipeBack(_:)))
        backSwipeGesture.edges = .left
        backSwipeGesture.delegate = self
        self.view.addGestureRecognizer(backSwipeGesture)
        
        if nightModeOn {
            nightModeEnabled()
        } else {
            nightModeDisabled()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeEnabled), name: .nightModeOn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeDisabled), name: .nightModeOff, object: nil)
    }
    
    func searchNearbyArticles(station: String) {
        if let location = self.mrtStationMap[station] {
            guard let lat = location["latitude"] as? Double, let lng = location["longitude"] as? Double else {
                self.locationLabel.text = "Could not get location for \(station)"
                return
            }
            self.locationLabel.text = "Fetching articles near \(station)"
            self.getNearbyFeed(lat: lat, lng: lng, address: station, radius: 2000)
        } else {
            self.locationLabel.text = "Could not get location for \(station)"
        }
    }
    
    @objc func nightModeEnabled() {
        enableNightMode()
        self.tableView.reloadData()
    }
    
    @objc func nightModeDisabled() {
        disableNightMode()
        self.tableView.reloadData()
    }
    
    func enableNightMode() {
        nightModeOn = true
        self.view.backgroundColor = ResourcesNight.COLOR_BG_MAIN
        self.tableView.backgroundColor = ResourcesNight.CARD_BG_COLOR
        self.locationBackgroundView.backgroundColor = ResourcesNight.COLOR_BG_MAIN
        self.searchTextField.theme = SearchTextFieldTheme.darkTheme()
        
        textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        self.locationLabel.textColor = textColor
    }
    
    func disableNightMode() {
        nightModeOn = false
        self.view.backgroundColor = ResourcesDay.COLOR_BG_MAIN
        self.tableView.backgroundColor = ResourcesDay.CARD_BG_COLOR
        self.locationBackgroundView.backgroundColor = ResourcesDay.COLOR_BG_MAIN
        self.searchTextField.theme = SearchTextFieldTheme.lightTheme()
        
        textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        self.locationLabel.textColor = textColor
    }
    
    @objc func didSwipeBack(_ sender: UIScreenEdgePanGestureRecognizer) {
        let dX = sender.translation(in: self.view).x
        if sender.state == .ended {
            let fraction = abs(dX/self.view.bounds.width)
            if fraction > 0.3 {
                dismiss(animated: true, completion: nil)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("received location update")
        guard let location = manager.location else {
            return
        }
        
        var address: String?;
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                self.view.makeToast("Error getting your location")
                print(error.localizedDescription)
                return
            }
            if let addr = placemarks?.first?.thoroughfare {
                address = addr
                self.locationLabel.text = "Fetching articles near \(address ?? "")"
            } else {
                self.locationLabel.text = "Failed to get your address"
                return
            }
            self.getNearbyFeed(lat: location.coordinate.latitude, lng: location.coordinate.longitude, address: address ?? "", radius: 2000)
        }
    }
    
    func getNearbyFeed(lat: Double, lng: Double, address: String, radius: Double) {
        nearbyList.removeAll()
        self.dataSource.getNearbyFeed(lat: lat, lng: lng, radius: radius, onComplete: { (articleList) in
            if articleList.count == 0 {
                self.view.makeToast("Could not find articles near \(address)")
                self.locationLabel.text = "Error getting articles near \(address)"
                return
            }
            self.nearbyList.append(contentsOf: articleList)
            self.addFeedFilters()
            self.locationLabel.text = "Showing articles near \(address)"
            self.tableView.reloadData()
        })
    }
    
    func addFeedFilters() {
        if selectedThemes.count == 0 {
            self.filteredNearbyList = self.nearbyList
        } else {
            self.filteredNearbyList.removeAll()
            for article in self.nearbyList {
                for theme in selectedThemes {
                    if article.mainTheme == theme {
                        self.filteredNearbyList.append(article)
                    }
                }
            }
        }
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredNearbyList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NearbyArticleTvCell", for: indexPath) as! NearbyArticleTvCell
        
        let article = filteredNearbyList[indexPath.row]
        cell.cellTextColor = textColor
        cell.populateCell(article: article)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let article = filteredNearbyList[indexPath.row]
        dataSource.recordOpenArticleDetails(articleId: article.objectID, mainTheme: article.mainTheme ?? "General")
        if article.link != nil && article.link != "" {
            openArticle(article.objectID)
        } else {
            openComments(article.objectID)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            filteredNearbyList.remove(at: indexPath.row)
            self.tableView.reloadData()
        }
    }
    
    @IBAction func didTapBackButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapSearchButton(_ sender: Any) {
        if let view = searchBackgroundView {
            if view.isHidden {
                view.isHidden = false
                view.becomeFirstResponder()
            } else {
                view.resignFirstResponder()
                view.isHidden = true
            }
        }
    }
    
    @IBAction func didTapFilterButton(_ sender: Any) {
        
        let selectionMenu = RSSelectionMenu(selectionStyle: .multiple, dataSource: themeArray) { (cell, theme, indexPath) in
            cell.textLabel?.text = theme
            cell.textLabel?.textColor = self.textColor
            cell.backgroundColor = self.nightModeOn ? ResourcesNight.CARD_BG_COLOR : ResourcesDay.CARD_BG_COLOR
        }
        
        selectionMenu.setSelectedItems(items: self.selectedThemes) { (item, index, selected, selectedThemes)  in
            self.selectedThemes = selectedThemes
        }
        
        selectionMenu.onDismiss = { selectedThemes in
            if selectedThemes.count == 0 {
                self.filteredNearbyList = self.nearbyList
            } else {
                self.filteredNearbyList.removeAll()
                for article in self.nearbyList {
                    for theme in selectedThemes {
                        if article.mainTheme == theme {
                            self.filteredNearbyList.append(article)
                        }
                    }
                }
            }
            self.tableView.reloadData()
        }
        
        selectionMenu.tableView?.backgroundColor = nightModeOn ? ResourcesNight.CARD_BG_COLOR : ResourcesDay.CARD_BG_COLOR
        
        selectionMenu.show(style: .present, from: self)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataSource.removeFeedObservers()
    }
}

extension NearbyViewController: ArticleListTvCellDelegate {
    
    func openArticle(_ articleId: String) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "WebView") as? WebViewViewController
        vc?.articleId = articleId
        self.present(vc!, animated: true, completion: nil)
    }
    
    func openComments(_ articleId: String) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Comment") as? CommentViewController
        vc?.articleId = articleId
        self.present(vc!, animated:true, completion: nil)
    }
    
    
}

extension NearbyViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        var address = ""
        var isStationFound = false
        for station in mrtStationNames {
            if station.lowercased().contains(text.lowercased()) {
                address = station
                isStationFound = true
            }
        }
        
        if !isStationFound {
            self.view.makeToast("Please choose from one of the MRT Stations suggested")
            return
        }
        
        searchNearbyArticles(station: address)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        let searchSelectionMenu = RSSelectionMenu(selectionStyle: .single, dataSource: filteredStationNames) { (cell, name, indexPath) in
            cell.textLabel?.text = name
            cell.textLabel?.textColor = self.textColor
            cell.backgroundColor = self.nightModeOn ? ResourcesNight.CARD_BG_COLOR : ResourcesDay.CARD_BG_COLOR
        }
        searchSelectionMenu.setSelectedItems(items: self.selectedThemes) { (item, index, selected, selectedStations)  in
            self.selectedMrtStation = selectedStations[0]
        }
        
        searchSelectionMenu.onDismiss = { stations in
            self.searchNearbyArticles(station: stations[0])
        }
        
        searchSelectionMenu.tableView?.backgroundColor = nightModeOn ? ResourcesNight.CARD_BG_COLOR : ResourcesDay.CARD_BG_COLOR
        
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredStationNames.removeAll()
        for station in mrtStationNames {
            if station.lowercased().contains(searchText.lowercased()) {
                filteredStationNames.append(station)
            }
        }
    }
}

extension NearbyViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

