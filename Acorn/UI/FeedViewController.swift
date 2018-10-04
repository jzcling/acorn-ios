//
//  FeedViewController.swift
//  Acorn
//
//  Created by macOS on 31/7/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import SDWebImage
import Firebase
import FirebaseUI
import GoogleSignIn
import MaterialComponents
import DropDown
import Lightbox
import Toast_Swift
import DeviceKit

class FeedViewController: MDCCollectionViewController, FeedCvCellDelegate {
    
    @IBOutlet weak var notificationsButton: UIBarButtonItem!
    @IBOutlet weak var moreOptionsButton: UIBarButtonItem!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    lazy var uid = Auth.auth().currentUser!.uid
    lazy var token = appDelegate.token
    
    var floatingButtonOffset: CGFloat = 0.0
    var spinner: UIView?
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    let dataSource = DataSource.instance
    let loadTrigger: Int = 5
    
    var selectedFeed: String?
    var isFirstTimeLogin: Bool = false
    var wasRefreshCalled: Bool = false
    var subscriptionsDidChange: Bool = false
    
    let defaults = UserDefaults.standard
    var themeKey: String?
    var themeFilters: [String]?
    lazy var nightModeOn = defaults.bool(forKey: "nightModePref")
    
    // colors
    lazy var colorAccent = nightModeOn ? ResourcesNight.COLOR_ACCENT : ResourcesDay.COLOR_ACCENT
    lazy var colorPrimary = nightModeOn ? ResourcesNight.COLOR_PRIMARY : ResourcesDay.COLOR_PRIMARY
    lazy var colorBackground = nightModeOn ? ResourcesNight.COLOR_BG : ResourcesDay.COLOR_BG
    lazy var colorBackgroundMain = nightModeOn ? ResourcesNight.COLOR_BG_MAIN : ResourcesDay.COLOR_BG_MAIN
    lazy var colorCardBackground = nightModeOn ? ResourcesNight.CARD_BG_COLOR : ResourcesDay.CARD_BG_COLOR
    lazy var colorCardText = nightModeOn ? ResourcesNight.CARD_TEXT_COLOR : ResourcesDay.CARD_TEXT_COLOR
    lazy var colorCardTextFaint = nightModeOn ? ResourcesNight.CARD_TEXT_COLOR_FAINT : ResourcesDay.CARD_TEXT_COLOR_FAINT
    
    var articleList = [Article]() {
        didSet {
            self.collectionView?.reloadData()
        }
    }
    
    let bottomBarView = MDCBottomAppBarView()
    lazy var subscriptionsButton = { () -> UIBarButtonItem in
        let button = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_checklist"), style: .plain, target: self, action: #selector(getSubscriptionsFeed))
        button.accessibilityLabel = "Subscriptions"
        button.tintColor = colorAccent
        return button
    }()
   lazy var recentButton = { () -> UIBarButtonItem in
        let button = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_history"), style: .plain, target: self, action: #selector(getRecentFeed))
        button.accessibilityLabel = "Recent"
        button.tintColor = UIColor.lightGray
        return button
    }()
    lazy var trendingButton = { () -> UIBarButtonItem in
        let button = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_trending_up"), style: .plain, target: self, action: #selector(getTrendingFeed))
        button.accessibilityLabel = "Trending"
        button.tintColor = UIColor.lightGray
        return button
    }()
    lazy var savedButton = { () -> UIBarButtonItem in
        let button = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_star"), style: .plain, target: self, action: #selector(getSavedFeed))
        button.accessibilityLabel = "Saved articles"
        button.tintColor = UIColor.lightGray
        return button
    }()
    
    var insets: UIEdgeInsets?
    var cellWidth: CGFloat?
    
    override func awakeFromNib() {
        bottomBarView.autoresizingMask = [ .flexibleWidth, .flexibleTopMargin ]
        view.addSubview(bottomBarView)
        
        // Add touch handler to the floating button.
        bottomBarView.floatingButton.addTarget(self, action: #selector(didTapFloatingButton), for: .touchUpInside)
        
        // Set the image on the floating button.
        bottomBarView.floatingButton.setImage(#imageLiteral(resourceName: "ic_plus"), for: .normal)
        bottomBarView.floatingButton.setImage(#imageLiteral(resourceName: "ic_plus"), for: .highlighted)
        bottomBarView.floatingButton.setImageTintColor(.white, for: .normal)
        bottomBarView.floatingButton.setImageTintColor(.white, for: .highlighted)
        bottomBarView.floatingButton.accessibilityLabel = "Create post"
        
        // Set the position of the floating button.
        bottomBarView.floatingButtonPosition = .trailing
        
        // Theme the floating button.
        let colorScheme = MDCBasicColorScheme(primaryColor: colorAccent)
        MDCButtonColorThemer.apply(colorScheme, to: bottomBarView.floatingButton)
        
        // Configure the navigation buttons to be shown on the bottom app bar.
        
        navigationController?.setToolbarHidden(true, animated: false)
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = colorPrimary
        
        bottomBarView.leadingBarButtonItems = [ subscriptionsButton, recentButton, trendingButton, savedButton ]
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        guard let collectionView = collectionView else {
            return
        }
        
        if nightModeOn {
            enableNightMode()
        } else {
            disableNightMode()
        }
        
        self.styler.cellStyle = .card
        self.styler.cellLayoutType = .grid
        self.styler.gridColumnCount = 1
        self.insets = self.collectionView(collectionView,
                                         layout: collectionViewLayout,
                                         insetForSectionAt: 0)
        self.cellWidth = collectionView.bounds.width - (insets?.left)! - (insets?.right)!
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self,
                                 action: #selector(refreshOptions(sender:)),
                                 for: .valueChanged)
        collectionView.refreshControl = refreshControl
        
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeEnabled), name: .nightModeOn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeDisabled), name: .nightModeOff, object: nil)
    }
    
    @objc private func nightModeEnabled() {
        enableNightMode()
        self.collectionView?.reloadData()
    }
    
    @objc private func nightModeDisabled() {
        disableNightMode()
        self.collectionView?.reloadData()
    }
    
    func enableNightMode() {
        nightModeOn = true
        colorAccent = ResourcesNight.COLOR_ACCENT
        colorPrimary = ResourcesNight.COLOR_PRIMARY
        colorBackground = ResourcesNight.COLOR_BG
        colorBackgroundMain = ResourcesNight.COLOR_BG_MAIN
        colorCardBackground = ResourcesNight.CARD_BG_COLOR
        colorCardText = ResourcesNight.CARD_TEXT_COLOR
        colorCardTextFaint = ResourcesNight.CARD_TEXT_COLOR_FAINT
        
        self.collectionView?.backgroundColor = colorBackground
        if selectedFeed == "Subscriptions" {
            subscriptionsButton.tintColor = colorAccent
        } else if selectedFeed == "Recent" {
            recentButton.tintColor = colorAccent
        } else if selectedFeed == "Trending" {
            trendingButton.tintColor = colorAccent
        } else if selectedFeed == "Saved" {
            savedButton.tintColor = colorAccent
        }
        let colorScheme = MDCBasicColorScheme(primaryColor: colorAccent)
        MDCButtonColorThemer.apply(colorScheme, to: bottomBarView.floatingButton)
        bottomBarView.barTintColor = colorBackgroundMain
        
    }
    
    func disableNightMode() {
        nightModeOn = false
        colorAccent = ResourcesDay.COLOR_ACCENT
        colorPrimary = ResourcesDay.COLOR_PRIMARY
        colorBackground = ResourcesDay.COLOR_BG
        colorBackgroundMain = ResourcesDay.COLOR_BG_MAIN
        colorCardBackground = ResourcesDay.CARD_BG_COLOR
        colorCardText = ResourcesDay.CARD_TEXT_COLOR
        colorCardTextFaint = ResourcesDay.CARD_TEXT_COLOR_FAINT
        
        self.collectionView?.backgroundColor = colorBackground
        if selectedFeed == "Subscriptions" {
            subscriptionsButton.tintColor = colorAccent
        } else if selectedFeed == "Recent" {
            recentButton.tintColor = colorAccent
        } else if selectedFeed == "Trending" {
            trendingButton.tintColor = colorAccent
        } else if selectedFeed == "Saved" {
            savedButton.tintColor = colorAccent
        }
        let colorScheme = MDCBasicColorScheme(primaryColor: colorAccent)
        MDCButtonColorThemer.apply(colorScheme, to: bottomBarView.floatingButton)
        bottomBarView.barTintColor = colorBackgroundMain
        
    }
    
    @objc private func refreshOptions(sender: UIRefreshControl) {
        wasRefreshCalled = true
        reloadFeed()
        sender.endRefreshing()
        wasRefreshCalled = false
    }
    
    private func reloadFeed() {
        resetView()
        loadData()
    }
    
    private func resetView() {
        resetButtonTints()
        dataSource.removeFeedObservers()
        articleList = [Article]()
        cleanCollectionView()
    }
    
    override func viewWillLayoutSubviews() {
        let size = bottomBarView.sizeThatFits(view.bounds.size)
        let bottomBarViewFrame = CGRect(x: 0,
                                        y: view.bounds.size.height - size.height,
                                        width: size.width,
                                        height: size.height)
        bottomBarView.frame = bottomBarViewFrame
        MDCSnackbarManager.setBottomOffset(bottomBarView.frame.height)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        if let currentUser = Auth.auth().currentUser  {
            self.uid = currentUser.uid
            
            dataSource.getUser(user: currentUser) { (retrievedUser) in
                if let retrievedUser = retrievedUser {
                    if !self.isUserEmailVerified(user: currentUser) { self.showEmailVerificationAlert(user: currentUser) }
                    
                    self.dataSource.getThemeSubscriptions(user: currentUser) { themePrefs in
                        self.themeKey = self.defaults.string(forKey: "themeKey")
                        self.themeFilters = self.defaults.stringArray(forKey: "themeFilters")
                        
                        // If user has no theme prefs, go to theme selection scene
                        
                        if self.themeKey == nil {
                            self.isFirstTimeLogin = true
                            self.performSegue(withIdentifier: "Edit Subscriptions", sender: self)
                        }
                        
                        retrievedUser.uid = self.uid
                        retrievedUser.displayName = currentUser.displayName ?? ""
                        retrievedUser.token = self.token ?? ""
                        retrievedUser.email = currentUser.email ?? ""
                        retrievedUser.device = Device().description
                        retrievedUser.creationTimeStamp = (currentUser.metadata.creationDate?.timeIntervalSince1970 ?? 0) * 1000
                        retrievedUser.lastSignInTimeStamp = (currentUser.metadata.lastSignInDate?.timeIntervalSince1970 ?? 0) * 1000
                        
                        self.dataSource.setUser(retrievedUser.toDict())
                        
                        self.loadData()
                        self.loadNotifications()
                    }
                } else {
                    let acornUser = AcornUser(uid: self.uid, displayName: currentUser.displayName ?? "", token: self.token ?? "", email: currentUser.email ?? "", device: Device().description, creationTimeStamp: (currentUser.metadata.creationDate?.timeIntervalSince1970 ?? 0) * 1000, lastSignInTimeStamp: (currentUser.metadata.lastSignInDate?.timeIntervalSince1970 ?? 0) * 1000)
                    
                    self.dataSource.setUser(acornUser.toDict())
                    
                    self.performSegue(withIdentifier: "Edit Subscriptions", sender: self)
                }
                
                
            }
            
            //            Crashlytics.sharedInstance().setUserIdentifier(currentUser.uid)
        } else {
            launchLogin()
            return
        }
        
        MDCSnackbarManager.setBottomOffset(bottomBarView.frame.height)
        navigationItem.leftBarButtonItems?[0].accessibilityLabel = "Notifications"
        navigationItem.rightBarButtonItems?[0].accessibilityLabel = "More options"
        navigationItem.rightBarButtonItems?[1].accessibilityLabel = "Search articles"
    }
    
    func launchLogin() {
        let authViewController = FUIAuth.defaultAuthUI()?.authViewController()
        authViewController?.navigationBar.isHidden = true
        self.present(authViewController!, animated: true, completion: nil)
    }
    
    func loadData() {
        spinner = displaySpinner()
        switch selectedFeed {
        case "Subscriptions":
            getSubscriptionsFeed()
        case "Recent":
            getRecentFeed()
        case "Trending":
            getTrendingFeed()
        case "Saved":
            getSavedFeed()
        default:
            getSubscriptionsFeed()
        }
    }
    
    func loadNotifications() {
        if let notificationsDict = defaults.dictionary(forKey: "notifications") {
            if notificationsDict.count > 0 {
                notificationsButton.setBadge(text: String(notificationsDict.count))
            } else {
                notificationsButton.removeBadge()
            }
        } else {
            notificationsButton.removeBadge()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataSource.removeFeedObservers()
        MDCSnackbarManager.setBottomOffset(0)
        if let spinner = spinner {
            removeSpinner(spinner)
        }
    }
    
    @objc func getSubscriptionsFeed() {
        
        self.view.makeToast("Subscriptions")
        if selectedFeed != "Subscriptions" || wasRefreshCalled || subscriptionsDidChange {
            resetView()
            selectedFeed = "Subscriptions"
            self.subscriptionsButton.tintColor = self.colorAccent
            dataSource.getSubscriptionsFeed() { (articles: [Article]) -> () in
                self.articleList = articles
                
                self.collectionView?.reloadData()
                self.collectionViewLayout.invalidateLayout()
                if let spinner = self.spinner { self.removeSpinner(spinner) }
            }
        } else {
            if let spinner = self.spinner { self.removeSpinner(spinner) }
        }
    }
    
    func getMoreSubscriptionsFeed(startAt: Double) {
        if selectedFeed != "Subscriptions" { return }
        let initialList = self.articleList
        
        
        dataSource.getSubscriptionsFeed(startAt: startAt) { (articles: [Article]) -> () in
            var combinedList = Array(initialList.dropLast())
            combinedList.append(contentsOf: articles)
            self.articleList = combinedList
            
            self.collectionView?.reloadData()
            self.collectionViewLayout.invalidateLayout()
            if let spinner = self.spinner { self.removeSpinner(spinner) }
        }
    }
    
    @objc func getRecentFeed() {
        
        self.view.makeToast("Recent")
        if selectedFeed != "Recent" || wasRefreshCalled {
            resetView()
            selectedFeed = "Recent"
            self.recentButton.tintColor = self.colorAccent
            dataSource.getRecentFeed() { (articles: [Article]) -> () in
                self.articleList = articles
                
                self.collectionView?.reloadData()
                self.collectionViewLayout.invalidateLayout()
                if let spinner = self.spinner { self.removeSpinner(spinner) }
            }
        } else {
            if let spinner = self.spinner { self.removeSpinner(spinner) }
        }
    }
    
    func getMoreRecentFeed(startAt: Double) {
        if selectedFeed != "Recent" { return }
        let initialList = self.articleList
        
        
        dataSource.getRecentFeed(startAt: startAt) { (articles: [Article]) -> () in
            var combinedList = Array(initialList.dropLast())
            combinedList.append(contentsOf: articles)
            self.articleList = combinedList
            
            self.collectionView?.reloadData()
            self.collectionViewLayout.invalidateLayout()
            if let spinner = self.spinner { self.removeSpinner(spinner) }
        }
    }
    
    @objc func getTrendingFeed() {
        
        self.view.makeToast("Trending")
        if selectedFeed != "Trending" || wasRefreshCalled {
            resetView()
            selectedFeed = "Trending"
            self.trendingButton.tintColor = self.colorAccent
            dataSource.getTrendingFeed() { (articles: [Article]) -> () in
                self.articleList = articles
                
                self.collectionView?.reloadData()
                self.collectionViewLayout.invalidateLayout()
                if let spinner = self.spinner { self.removeSpinner(spinner) }
            }
        } else {
            if let spinner = self.spinner { self.removeSpinner(spinner) }
        }
    }
    
    func getMoreTrendingFeed(startAt: String) {
        if selectedFeed != "Trending" { return }
        let initialList = self.articleList
        
        
        dataSource.getTrendingFeed(startAt: startAt) { (articles: [Article]) -> () in
            var combinedList = Array(initialList.dropLast())
            combinedList.append(contentsOf: articles)
            self.articleList = combinedList
            
            self.collectionView?.reloadData()
            self.collectionViewLayout.invalidateLayout()
            if let spinner = self.spinner { self.removeSpinner(spinner) }
        }
    }
    
    @objc func getSavedFeed() {
        
        self.view.makeToast("Saved Articles")
        if selectedFeed != "Saved" || wasRefreshCalled {
            resetView()
            selectedFeed = "Saved"
            self.savedButton.tintColor = self.colorAccent
            dataSource.getSavedFeed(startAt: 0) { (articles: [Article]) -> () in
                self.articleList = articles
                
                self.collectionView?.reloadData()
                self.collectionViewLayout.invalidateLayout()
                if let spinner = self.spinner { self.removeSpinner(spinner) }
            }
        } else {
            if let spinner = self.spinner { self.removeSpinner(spinner) }
        }
    }
    
    func getMoreSavedFeed(startAt: Int) {
        if selectedFeed != "Saved" { return }
        let initialList = self.articleList
        
        
        dataSource.getSavedFeed(startAt: startAt) { (articles: [Article]) -> () in
            var combinedList = Array(initialList.dropLast())
            combinedList.append(contentsOf: articles)
            self.articleList = combinedList
            
            self.collectionView?.reloadData()
            self.collectionViewLayout.invalidateLayout()
            if let spinner = self.spinner { self.removeSpinner(spinner) }
        }
    }
    
    func resetButtonTints() {
        self.subscriptionsButton.tintColor = UIColor.lightGray
        self.recentButton.tintColor = UIColor.lightGray
        self.trendingButton.tintColor = UIColor.lightGray
        self.savedButton.tintColor = UIColor.lightGray
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Create Post" {
            let vc = segue.destination as! CreatePostViewController
            vc.delegate = self
        } else if segue.identifier == "Edit Subscriptions" {
            let vc = segue.destination as! SubscriptionsViewController
            vc.isFirstTimeLogin = self.isFirstTimeLogin
            vc.vc = self
        } else if segue.identifier == "Notifications" {
            let vc = segue.destination as! NotificationsViewController
        }
    }
    
    @objc private func didTapFloatingButton() {
        performSegue(withIdentifier: "Create Post", sender: self)
    }
    
    @IBAction func didTapSearch(_ sender: Any) {
        performSegue(withIdentifier: "Search", sender: self)
    }
    
   
    @IBAction func didTapMoreOptions(_ sender: Any) {
        let dropdown = DropDown()
        dropdown.anchorView = moreOptionsButton
        dropdown.dataSource = ["Edit Subscriptions", "Settings", "Log Out", "Share App Invite"]//, "Recommended Articles Push"]
        dropdown.width = 200
        dropdown.direction = .bottom
        dropdown.backgroundColor = nightModeOn ? ResourcesNight.OPTIONS_BG_COLOR : ResourcesDay.OPTIONS_BG_COLOR
        dropdown.textColor = nightModeOn ? ResourcesNight.OPTIONS_TEXT_COLOR : ResourcesDay.OPTIONS_TEXT_COLOR
        dropdown.bottomOffset = CGPoint(x: 0, y: (dropdown.anchorView?.plainView.bounds.height)!)
        dropdown.selectionAction = { (index: Int, item: String) in
            if item == "Edit Subscriptions" {
                self.performSegue(withIdentifier: "Edit Subscriptions", sender: self)
            } else if item == "Settings" {
                self.performSegue(withIdentifier: "Settings", sender: self)
            } else if item == "Log Out" {
                let ac = UIAlertController(title: nil, message: "Would you like to log out?", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                ac.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
                    do {
                        try Auth.auth().signOut()
                    } catch {
                        
                    }
                    self.resetView()
                    self.selectedFeed = nil
                    self.launchLogin()
                }))
                self.present(ac, animated: true, completion: nil)
            } else if item == "Share App Invite" {
                let shareText = "Get your favourite blog articles all in one app!"
                let shareUrl = URL(string: "http://acorncommunity.sg")
                let shareItems = [shareText, shareUrl ?? ""] as [Any]
                let activityController = UIActivityViewController(activityItems: shareItems,  applicationActivities: nil)
                DispatchQueue.main.async {
                    self.present(activityController, animated: true)
                }	
//            } else if item == "Recommended Articles Push" {
//                let recArticlesPref = self.defaults.bool(forKey: "recArticlesNotifPref")
//                if recArticlesPref {
//                    let waitTime = Double(arc4random_uniform(10))
//
//                    DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
//                        self.appDelegate.scheduleRecommendedArticlesPush() {
//                            self.appDelegate.updateNotificationsBadge()
//                        }
//                    }
//                }
            }
        }
        dropdown.show()
    }
    
    @IBAction func didTapNotifications(_ sender: Any) {
        performSegue(withIdentifier: "Notifications", sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return articleList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let article = articleList[indexPath.item]
        
        if selectedFeed == "Saved" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellSaved", for: indexPath) as! FeedCvCellSaved
            
            cell.delegate = self
            cell.article = article
            cell.textColor = colorCardText
            cell.textColorFaint = colorCardTextFaint
            
            cell.backgroundColor = colorCardBackground
            
            cell.populateCell(article: article)
            
            return cell
        }
        
        if article.type == "article" {
            if (article.imageUrl != nil && article.imageUrl != "") {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCell", for: indexPath) as! FeedCvCell
                cell.delegate = self
                cell.article = article
                cell.textColor = colorCardText
                cell.textColorFaint = colorCardTextFaint
                
                cell.backgroundColor = colorCardBackground
                
                cell.sourceLabelWidthConstraint.constant = cellWidth!*7/24
                
                cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellNoImage", for: indexPath) as! FeedCvCellNoImage
                cell.delegate = self
                cell.article = article
                cell.textColor = colorCardText
                cell.textColorFaint = colorCardTextFaint
                
                cell.backgroundColor = colorCardBackground
                
                cell.sourceLabelWidthConstraint.constant = cellWidth!/3
                
                cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                return cell
            }
        } else {
            if (article.link != nil && article.link != "") {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellPostWithArticle", for: indexPath) as! FeedCvCellPostWithArticle
                cell.delegate = self
                cell.article = article
                cell.textColor = colorCardText
                cell.textColorFaint = colorCardTextFaint
                
                cell.backgroundColor = colorCardBackground
                
                cell.sourceLabelWidthConstraint.constant = cellWidth!/3
                
                cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                return cell
            } else {
                if (article.postImageUrl != nil && article.postImageUrl != "") {
                    if (article.title != nil && article.title != "") {
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellPostWithArticle", for: indexPath) as! FeedCvCellPostWithArticle
                        cell.delegate = self
                        cell.article = article
                        cell.textColor = colorCardText
                        cell.textColorFaint = colorCardTextFaint
                        
                        cell.backgroundColor = colorCardBackground
                        
                        cell.sourceLabelWidthConstraint.constant = cellWidth!/3
                        
                        cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                        return cell
                    } else {
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellPost", for: indexPath) as! FeedCvCellPost
                        cell.delegate = self
                        cell.article = article
                        cell.textColor = colorCardText
                        cell.textColorFaint = colorCardTextFaint
                        
                        cell.backgroundColor = colorCardBackground
                        
                        cell.sourceLabelWidthConstraint.constant = cellWidth!/3
                        
                        cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                        return cell
                    }
                } else {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellPostNoImage", for: indexPath) as! FeedCvCellPostNoImage
                    cell.delegate = self
                    cell.article = article
                    cell.textColor = colorCardText
                    cell.textColorFaint = colorCardTextFaint
                    
                    cell.backgroundColor = colorCardBackground
                    
                    cell.sourceLabelWidthConstraint.constant = cellWidth!/3
                    
                    cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                    return cell
                }
            }
        }
    }
    
    func openArticle(_ articleId: String) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "WebView") as? WebViewViewController
        vc?.articleId = articleId
        vc?.feedVC = self
        present(vc!, animated: true, completion: nil)
    }
    
    func openComments(_ articleId: String) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Comment") as? CommentViewController
        vc?.articleId = articleId
        present(vc!, animated:true, completion: nil)
    }
    
    func openShareActivity(_ urlLink: String?) {
        if let shareLink = urlLink {
            let shareText = "Shared using Acorn: Your favourite blogs in a nutshell"
            let shareUrl = URL(string: shareLink)
            let shareItems = [shareText, shareUrl ?? ""] as [Any]
            
            let activityController = UIActivityViewController(activityItems: shareItems,  applicationActivities: nil)
            DispatchQueue.main.async {
                self.present(activityController, animated: true)
            }
        }
    }
    
    func openImage(_ urlLink: String?) {
        if let link = urlLink {
            let image = LightboxImage(imageURL: URL(string: link)!)
            let lightbox = LightboxController(images: [image])
            lightbox.dynamicBackground = true
            present(lightbox, animated: true, completion: nil)
        }
    }
    
    func openOptions(anchor: UIView, post: Article) {
        let dropdown = DropDown()
        dropdown.anchorView = anchor
        dropdown.dataSource = ["Report post"]
        dropdown.width = 100
        dropdown.direction = .bottom
        dropdown.backgroundColor = nightModeOn ? ResourcesNight.CARD_BG_COLOR : ResourcesDay.CARD_BG_COLOR
        dropdown.textColor = nightModeOn ? ResourcesNight.CARD_TEXT_COLOR : ResourcesDay.CARD_TEXT_COLOR
        dropdown.bottomOffset = CGPoint(x: 0, y: (dropdown.anchorView?.plainView.bounds.height)!)
        dropdown.selectionAction = { (index: Int, item: String) in
            if item == "Report post" {
                self.dataSource.reportPost(post)
            }
        }
        dropdown.show()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellHeightAt indexPath: IndexPath) -> CGFloat {
        let article = articleList[indexPath.item]
        
        if selectedFeed == "Saved" {
            return 138
        }
        
        let cellDefaultHeight: CGFloat = 116
        let imageHeight = self.cellWidth! / 16.0 * 9.0
        
        if article.type == "article" {
            let tempTitleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.cellWidth! - 24, height: CGFloat.greatestFiniteMagnitude))
            tempTitleLabel.numberOfLines = 0
            tempTitleLabel.lineBreakMode = .byWordWrapping
            tempTitleLabel.font = UIFont.systemFont(ofSize: 18.0)
            tempTitleLabel.text = article.title
            tempTitleLabel.sizeToFit()
            let titleHeight = tempTitleLabel.frame.height
            
            if (article.imageUrl != nil && article.imageUrl != "") {
                return cellDefaultHeight + titleHeight + imageHeight
            } else {
                return cellDefaultHeight + titleHeight
            }
        } else {
            let tempTitleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.cellWidth! - 24, height: CGFloat.greatestFiniteMagnitude))
            tempTitleLabel.numberOfLines = 0
            tempTitleLabel.lineBreakMode = .byWordWrapping
            tempTitleLabel.font = UIFont.systemFont(ofSize: 18.0)
            tempTitleLabel.text = article.postText
            tempTitleLabel.sizeToFit()
            let titleHeight = tempTitleLabel.frame.height
            
            if (article.link != nil && article.link != "") {
                let tempArticleTitleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.cellWidth! - 148, height: CGFloat.greatestFiniteMagnitude))
                tempArticleTitleLabel.numberOfLines = 0
                tempArticleTitleLabel.lineBreakMode = .byWordWrapping
                tempArticleTitleLabel.font = UIFont.systemFont(ofSize: 16.0)
                tempArticleTitleLabel.text = article.postText
                tempArticleTitleLabel.sizeToFit()
                let articleTitleHeight = tempArticleTitleLabel.frame.height
                
                let articleCardHeightAdjustment = max(articleTitleHeight + 25, 90)
                
                return 144 + titleHeight + articleCardHeightAdjustment
            } else {
                if (article.postImageUrl != nil && article.postImageUrl != "") {
                    return cellDefaultHeight + titleHeight + imageHeight
                } else {
                    return cellDefaultHeight + titleHeight
                }
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == (self.articleList.count - self.loadTrigger) {
            let lastArticle = articleList.last
            switch selectedFeed {
            case "Subscriptions":
                getMoreSubscriptionsFeed(startAt: (lastArticle?.pubDate)!)
            case "Recent":
                getMoreRecentFeed(startAt: (lastArticle?.pubDate)!)
            case "Trending":
                getMoreTrendingFeed(startAt: (lastArticle?.trendingIndex)!)
            case "Saved":
                getMoreSavedFeed(startAt: articleList.count)
            default: break
                
            }
        }
    }
    
}

extension MDCCollectionViewController {
    var feedViewController: FeedViewController? {
        return navigationController?.viewControllers[0] as? FeedViewController
    }
    
    internal func cleanCollectionView() {
        if collectionView!.numberOfItems(inSection: 0) > 0 {
            collectionView!.scrollToItem(at: NSIndexPath(item: 0, section: 0) as IndexPath, at: .top, animated: true)
            collectionView!.reloadSections([0])
        }
    }
}

extension UIViewController {
    func displaySpinner() -> UIView {
        let spinnerView = UIView.init(frame: view.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            self.view.addSubview(spinnerView)
        }
        return spinnerView
    }
    
    func removeSpinner(_ spinner: UIView) {
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
        }
    }
    
    func showEmailVerificationAlert(user: User) {
        let ac = UIAlertController(title: nil, message: "Please verify your email address.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        ac.addAction(UIAlertAction(title: "Re-send verification email", style: .destructive, handler: { _ in
            user.sendEmailVerification()
        }))
        self.present(ac, animated: true, completion: nil)
    }
    
    func isUserEmailVerified(user: User) -> (Bool) {
        user.reload()
        return user.isEmailVerified
    }
}

extension FeedViewController: CreatePostDelegate {
    func postCreated() {
        dismiss(animated: true, completion: { self.view.makeToast("Post created!") })
    }
}

