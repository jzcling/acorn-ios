//
//  SearchViewController.swift
//  Acorn
//
//  Created by macOS on 3/9/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import InstantSearch

class SearchViewController: UIViewController {
    typealias HitType = Article
    
    let searchTriggeringMode: SearchTriggeringMode
    
    let stackView = UIStackView()
    var searcher: SingleIndexSearcher
    
    let queryInputInteractor: QueryInputInteractor
    let searchBarController: SearchBarController
    
    let hitsInteractor: HitsInteractor<HitType>
    let hitsTableViewController: HitsTableViewController<HitType>
    
    var nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    let dataSource = NetworkDataSource.instance
    
    init(algoliaApiKey: String) {
        self.searchTriggeringMode = .searchAsYouType
        self.searchBarController = .init(searchBar: .init())
        self.queryInputInteractor = .init()
        self.hitsInteractor = .init(infiniteScrolling: .on(withOffset: 10), showItemsOnEmptyQuery: false)
        self.hitsTableViewController = HitsTableViewController(searchBar: self.searchBarController.searchBar)
        self.searcher = SingleIndexSearcher(appID: self.dataSource.algoliaAppId, apiKey: algoliaApiKey, indexName: self.dataSource.algoliaIndexName)
        super.init(nibName: .none, bundle: .none)
        self.title = "Search"
        self.view.tintColor = ResourcesDay.COLOR_PRIMARY
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        
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
        self.hitsTableViewController.reload()
    }
    
    @objc func nightModeDisabled() {
        disableNightMode()
        self.hitsTableViewController.reload()
    }
    
    func enableNightMode() {
        nightModeOn = true
        self.view.backgroundColor = ResourcesNight.COLOR_BG
        self.hitsTableViewController.tableView.backgroundColor = ResourcesNight.COLOR_BG
        self.hitsTableViewController.cardBackgroundColor = ResourcesNight.CARD_BG_COLOR
        (self.searchBarController.searchBar.value(forKey: "searchField") as? UITextField)?.textColor = ResourcesNight.CARD_TEXT_COLOR
    }
    
    func disableNightMode() {
        nightModeOn = false
        self.view.backgroundColor = ResourcesDay.COLOR_BG
        self.hitsTableViewController.tableView.backgroundColor = ResourcesDay.COLOR_BG
        self.hitsTableViewController.cardBackgroundColor = ResourcesDay.CARD_BG_COLOR
        (self.searchBarController.searchBar.value(forKey: "searchField") as? UITextField)?.textColor = ResourcesDay.CARD_TEXT_COLOR
    }
    
    private func setup() {
        
        hitsTableViewController.tableView.register(SearchHitsTvCell.self, forCellReuseIdentifier: hitsTableViewController.cellIdentifier)
        
        hitsInteractor.connectSearcher(searcher)
        hitsInteractor.connectController(hitsTableViewController)
        
        queryInputInteractor.connectController(searchBarController)
        queryInputInteractor.connectSearcher(searcher, searchTriggeringMode: searchTriggeringMode)
        
        searcher.search()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBarController.searchBar.endEditing(true)
    }

}

private extension SearchViewController {
    
    func configureUI() {
        configureSearchBar()
        configureStackView()
        configureLayout()
    }
    
    func configureSearchBar() {
        let searchBar = searchBarController.searchBar
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.searchBarStyle = .minimal
    }
    
    func configureStackView() {
        stackView.spacing = 8
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func configureLayout() {
        
        searchBarController.searchBar.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        addChild(hitsTableViewController)
        hitsTableViewController.didMove(toParent: self)
        
        stackView.addArrangedSubview(searchBarController.searchBar)
        stackView.addArrangedSubview(hitsTableViewController.view)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
        
    }
    
}
