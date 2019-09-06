//
//  SavedArticlesViewController.swift
//  Acorn
//
//  Created by macOS on 11/10/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import RSSelectionMenu

class SavedArticlesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    @IBOutlet weak var filterButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    let defaults = UserDefaults.standard
    lazy var nightModeOn = defaults.bool(forKey: "nightModePref")
    var textColor: UIColor?
    
    var savedList = [Article]()
    var filteredSavedList = [Article]()
    
    let themeArray = ResourcesDay.THEME_LIST
    var selectedThemes = [String]()
    
    let dataSource = NetworkDataSource.instance
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    let loadTrigger = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 143
        
        self.filteredSavedList = self.savedList
        
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
        
        textColor = ResourcesNight.COLOR_DEFAULT_TEXT
    }
    
    func disableNightMode() {
        nightModeOn = false
        self.view.backgroundColor = ResourcesDay.COLOR_BG_MAIN
        self.tableView.backgroundColor = ResourcesDay.CARD_BG_COLOR
        
        textColor = ResourcesDay.COLOR_DEFAULT_TEXT
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
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredSavedList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedArticleTvCell", for: indexPath) as! SavedArticleTvCell
        
        let article = filteredSavedList[indexPath.row]
        cell.cellTextColor = textColor
        cell.populateCell(article: article)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let article = filteredSavedList[indexPath.row]
        dataSource.recordOpenArticleDetails(articleId: article.objectID, mainTheme: article.mainTheme ?? "General")
        if article.link != nil && article.link != "" {
            openArticle(article.objectID)
        } else {
            openComments(article.objectID)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let article = filteredSavedList[indexPath.row]
        if editingStyle == .delete {
            dataSource.updateArticleSave(article: article) {}
            dataSource.updateUserSave(article: article) {}
            filteredSavedList.remove(at: indexPath.row)
            self.tableView.reloadData()
        }
    }
    

//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        if indexPath.item == (self.savedList.count - self.loadTrigger) {
//            getMoreSavedFeed(startAt: self.savedList.count)
//        }
//    }
    
    func getMoreSavedFeed(startAt: Int) {
        let initialList = self.savedList
        let initialFilteredList = self.filteredSavedList
        
        dataSource.getSavedFeed(startAt: startAt, limit: 20) { (articles) in
            if articles.count <= 1 { return }
            var combinedList = Array(initialList.dropLast())
            combinedList.append(contentsOf: articles)
            self.savedList = combinedList
            self.addFeedFilters()
            if self.tableView.numberOfRows(inSection: 0) == initialFilteredList.count {
                self.getMoreSavedFeed(startAt: self.savedList.count)
            }
        }
    }
    
    func addFeedFilters() {
        if selectedThemes.count == 0 {
            self.filteredSavedList = self.savedList
        } else {
            self.filteredSavedList.removeAll()
            for article in self.savedList {
                for theme in selectedThemes {
                    if article.mainTheme == theme {
                        self.filteredSavedList.append(article)
                    }
                }
            }
        }
        self.searchBarSearchButtonClicked(searchBar)
    }
    
    @IBAction func didTapBackButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapSearchButton(_ sender: Any) {
        if searchBar.isHidden {
            searchBar.isHidden = false
            searchBar.becomeFirstResponder()
        } else {
            searchBar.resignFirstResponder()
            searchBar.isHidden = true
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
                self.filteredSavedList = self.savedList
            } else {
                self.filteredSavedList.removeAll()
                for article in self.savedList {
                    for theme in selectedThemes {
                        if article.mainTheme == theme {
                            self.filteredSavedList.append(article)
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

extension SavedArticlesViewController: ArticleListTvCellDelegate {
    
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

extension SavedArticlesViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        if !text.isEmpty {
            let tempFilteredSavedList = self.filteredSavedList
            self.filteredSavedList.removeAll()
            for article in tempFilteredSavedList {
                if article.title?.range(of: text, options: .caseInsensitive) != nil ||
                    article.mainTheme?.range(of: text, options: .caseInsensitive) != nil ||
                    article.source?.range(of: text, options: .caseInsensitive) != nil ||
                    article.postAuthor?.range(of: text, options: .caseInsensitive) != nil ||
                    article.postText?.range(of: text, options: .caseInsensitive) != nil {
                        self.filteredSavedList.append(article)
                }
            }
            self.tableView.reloadData()
            filteredSavedList = tempFilteredSavedList
        } else {
            self.tableView.reloadData()
        }
        
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.tableView.reloadData()
    }
}

extension SavedArticlesViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
