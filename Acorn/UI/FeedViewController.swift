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
import Crashlytics
import Reachability
import MaterialShowcase
import CoreLocation
import PIPKit
import FBAudienceNetwork

class FeedViewController: MDCCollectionViewController {
    
    @IBOutlet weak var navBarTitleButton: UIButton!
    @IBOutlet weak var notificationsButton: UIBarButtonItem!
    @IBOutlet weak var moreOptionsButton: UIBarButtonItem!
    @IBOutlet weak var userButton: UIBarButtonItem!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let globals = Globals.instance
    let localDb = LocalDb.instance
    
    var user: User?
    var uid: String?
    lazy var token = globals.token
    var acornUser: AcornUser?
    var isUserPremium: Bool = false
    var referredBy: String?
    
    var floatingButtonOffset: CGFloat = 0.0
    var spinner: UIView?
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    let dataSource = NetworkDataSource.instance
    let loadTrigger: Int = 5
    
    var selectedFeed: String?
    var masterFeed: String?
    var specificFeed: String?
    var isFirstTimeLogin: Bool = false
    var didLogin: Bool = false
    var didLaunch: Bool = true
    var wasRefreshCalled: Bool = false
    var subscriptionsDidChange: Bool = false
    var feedDidChange: Bool = false
    
    let defaults = UserDefaults.standard
    var themeKey: String?
    var themeFilters: [String]?
    lazy var nightModeOn = defaults.bool(forKey: "nightModePref")
    
    var saveButtonToHighlight: UIButton?
    
    let locationManager = CLLocationManager()
    
    // colors
    lazy var colorAccent = nightModeOn ? ResourcesNight.COLOR_ACCENT : ResourcesDay.COLOR_ACCENT
    lazy var colorPrimary = nightModeOn ? ResourcesNight.COLOR_PRIMARY : ResourcesDay.COLOR_PRIMARY
    lazy var colorBackground = nightModeOn ? ResourcesNight.COLOR_BG : ResourcesDay.COLOR_BG
    lazy var colorBackgroundMain = nightModeOn ? ResourcesNight.COLOR_BG_MAIN : ResourcesDay.COLOR_BG_MAIN
    lazy var colorCardBackground = nightModeOn ? ResourcesNight.CARD_BG_COLOR : ResourcesDay.CARD_BG_COLOR
    lazy var colorCardText = nightModeOn ? ResourcesNight.CARD_TEXT_COLOR : ResourcesDay.CARD_TEXT_COLOR
    lazy var colorCardTextFaint = nightModeOn ? ResourcesNight.CARD_TEXT_COLOR_FAINT : ResourcesDay.CARD_TEXT_COLOR_FAINT
    lazy var colorCardTextRead = nightModeOn ? ResourcesNight.CARD_TEXT_COLOR_READ : ResourcesDay.CARD_TEXT_COLOR_READ
    
    var articleList = [AnyObject]()
    var articleListIds = [String]()
    var hitsArticles = [Article]()
    var videoList = [Video]()
    var savedArticleList = [Article]()
    var seenList = [String: String]()
    
    // Ads
    let nativeAdPlacementId = "353679552175190_353679795508499"
    var adLoader: FBNativeAdsManager?
    var adList = [FBNativeAd]()
    
    lazy var bottomBarView = MDCBottomNavigationBar()
    lazy var toastPosition = CGPoint(x: self.view.bounds.size.width / 2.0, y: (self.view.bounds.size.height - 30) - 10 - bottomBarView.frame.height)
    lazy var subscriptionsButton = { () -> UITabBarItem in
        let button = UITabBarItem(title: nil, image: #imageLiteral(resourceName: "ic_checklist"), tag: 0)
//        let button = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_checklist"), style: .plain, target: self, action: #selector(getSubscriptionsFeed))
        button.accessibilityLabel = "Subscriptions"
//        button.tintColor = colorAccent
        return button
    }()
    let trendingButton = { () -> UITabBarItem in
        let button = UITabBarItem(title: nil, image: #imageLiteral(resourceName: "ic_trending_up"), tag: 1)
//        let button = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_trending_up"), style: .plain, target: self, action: #selector(getTrendingFeed))
        button.accessibilityLabel = "Trending"
//        button.tintColor = UIColor.lightGray
        return button
    }()
    let dealsButton = { () -> UITabBarItem in
        let button = UITabBarItem(title: nil, image: #imageLiteral(resourceName: "ic_sale"), tag: 2)
//        let button = UITabBarItem(image: #imageLiteral(resourceName: "ic_sale"), style: .plain, target: self, action: #selector(getDealsFeed))
        button.accessibilityLabel = "Deals"
//        button.tintColor = UIColor.lightGray
        return button
    }()
    let savedButton = { () -> UITabBarItem in
        let button = UITabBarItem(title: nil, image: #imageLiteral(resourceName: "ic_star"), tag: 3)
//        let button = UITabBarItem(image: #imageLiteral(resourceName: "ic_star"), style: .plain, target: self, action: #selector(getSavedFeed))
        button.accessibilityLabel = "Saved articles"
//        button.tintColor = UIColor.lightGray
        return button
    }()
    let nearbyButton = { () -> UITabBarItem in
        let button = UITabBarItem(title: nil, image: #imageLiteral(resourceName: "ic_map_marker"), tag: 4)
//        let button = UITabBarItem(image: #imageLiteral(resourceName: "ic_map_marker"), style: .plain, target: self, action: #selector(getNearbyFeed))
        button.accessibilityLabel = "Nearby"
//        button.tintColor = UIColor.lightGray
        return button
    }()
    let videoButton = { () -> UITabBarItem in
        let button = UITabBarItem(title: nil, image: #imageLiteral(resourceName: "ic_youtube"), tag: 5)
//        let button = UITabBarItem(image: #imageLiteral(resourceName: "ic_youtube"), style: .plain, target: self, action: #selector(getVideoFeed))
        button.accessibilityLabel = "Videos"
//        button.tintColor = UIColor.red
        return button
    }()
    
    let floatingButton = { () -> MDCFloatingButton in
        let floatingButton = MDCFloatingButton()
        floatingButton.setImage(#imageLiteral(resourceName: "ic_plus"), for: .normal)
        floatingButton.setImage(#imageLiteral(resourceName: "ic_plus"), for: .highlighted)
        floatingButton.setImageTintColor(.white, for: .normal)
        floatingButton.setImageTintColor(.white, for: .highlighted)
        floatingButton.accessibilityLabel = "Create post"
        return floatingButton
    }()
    
    var insets: UIEdgeInsets?
    var cellWidth: CGFloat?
    
    let newContentPrompt = { () -> UIView in
        let prompt = UIView()
        let label = UILabel()
        prompt.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        prompt.addSubview(label)
        
        label.textAlignment = .center
        label.text = "New content awaits you! Tap to refresh"
        label.textColor = .white
        label.numberOfLines = 1
        label.font = UIFont .systemFont(ofSize: 13.0, weight: UIFont.Weight(rawValue: 1.0))
        label.sizeToFit()
        
        label.centerXAnchor.constraint(equalTo: prompt.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: prompt.centerYAnchor).isActive = true
        
        prompt.widthAnchor.constraint(equalToConstant: label.bounds.width + 16.0).isActive = true
        prompt.heightAnchor.constraint(equalToConstant: label.bounds.height + 8.0).isActive = true
        prompt.layer.cornerRadius = 12
        
        return prompt
    }()
    
    // Ad
    var bannerView: FBAdView?
    
    override func awakeFromNib() {
        print("awakefromnib")
//        bottomBarView.autoresizingMask = [ .flexibleWidth, .flexibleTopMargin ]
        view.addSubview(bottomBarView)
        view.addSubview(floatingButton)
        view.addSubview(newContentPrompt)
        
        bannerView = FBAdView(placementID: "353679552175190_355424738667338", adSize: kFBAdSizeHeight50Banner, rootViewController: self)
        if let bannerView = bannerView {
            bannerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                bannerView.widthAnchor.constraint(equalToConstant: view.bounds.size.width),
                bannerView.heightAnchor.constraint(equalToConstant: 50)
            ])
            bannerView.delegate = self
            view.addSubview(bannerView)
            bannerView.loadAd()
        }
        
        newContentPrompt.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        newContentPrompt.centerYAnchor.constraint(equalTo: view.topAnchor, constant: 100.0).isActive = true
        newContentPrompt.isHidden = true
        
        // Enable inclusion of safe area in size calcs
        bottomBarView.sizeThatFitsIncludesSafeArea = true
        
        let size = bottomBarView.sizeThatFits(view.bounds.size)
        var bottomBarFrame = CGRect(x: 0, y: view.bounds.height - size.height, width: size.width, height: size.height)
        
        //Extend the Bottom Navigation to the bottom of the screen
//        bottomBarFrame.size.height += view.safeAreaInsets.bottom
//        bottomBarFrame.origin.y -= view.safeAreaInsets.bottom
        bottomBarView.frame = bottomBarFrame
        
        // Add floating button.
        floatingButton.addTarget(self, action: #selector(didTapFloatingButton), for: .touchUpInside)
        
        // Theme the floating button.
        let colorScheme = MDCBasicColorScheme(primaryColor: colorAccent)
        MDCButtonColorThemer.apply(colorScheme, to: floatingButton)
        
        // Theme bottom navigation bar
        MDCBottomNavigationBarColorThemer.apply(colorScheme, to: bottomBarView)
        
        // Set navigation controller defaults
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = colorPrimary
        
        // Configure the navigation buttons to be shown on the bottom app bar.
        navigationController?.setToolbarHidden(true, animated: false)
        bottomBarView.items = [ subscriptionsButton, trendingButton, dealsButton, savedButton, nearbyButton, videoButton ]
        bottomBarView.selectedItem = bottomBarView.items.first
    }
    
    override func viewSafeAreaInsetsDidChange() {
        // Set the position of the floating button.
        // Done here as safeareainsets are 0 until this callback is triggered
        let height = CGFloat(48), width = CGFloat(48)
        let x = view.bounds.width - CGFloat(15) - width - view.safeAreaInsets.right
        if let bannerView = bannerView {
            let y = view.bounds.height - bottomBarView.frame.height - bannerView.frame.height - CGFloat(15) - height - view.safeAreaInsets.bottom
            floatingButton.frame = CGRect(x: x, y: y, width: width, height: height)
        } else {
            let y = view.bounds.height - bottomBarView.frame.height - CGFloat(15) - height - view.safeAreaInsets.bottom
            floatingButton.frame = CGRect(x: x, y: y, width: width, height: height)
        }
    }
    
    override func viewDidLoad() {
        print("viewDidLoad")
        super.viewDidLoad()
        
        guard let collectionView = collectionView else {
            return
        }
        
        localDb.openDatabase()
        
        bottomBarView.delegate = self
        
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
        
//        let collectionViewBottomConstraint = NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: bannerView, attribute: .top, multiplier: 1, constant: 0)
//        let bannerViewBottomConstraint = NSLayoutConstraint(item: bannerView, attribute: .bottom, relatedBy: .equal, toItem: self.bottomBarView, attribute: .top, multiplier: 1, constant: 0)
//        self.view.addConstraints([bannerViewBottomConstraint])
        
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
        colorCardTextRead = ResourcesNight.CARD_TEXT_COLOR_READ
        
        self.view.backgroundColor = colorBackgroundMain
        self.collectionView?.backgroundColor = colorBackground
        if selectedFeed == "Subscriptions" {
            subscriptionsButton.selectedImage?.sd_tintedImage(with: colorAccent)
        } else if selectedFeed == "Trending" {
            trendingButton.selectedImage?.sd_tintedImage(with: colorAccent)
        } else if selectedFeed == "Deals" {
            dealsButton.selectedImage?.sd_tintedImage(with: colorAccent)
        }
        let colorScheme = MDCBasicColorScheme(primaryColor: colorAccent)
        MDCButtonColorThemer.apply(colorScheme, to: floatingButton)
        bottomBarView.barTintColor = colorBackgroundMain
        newContentPrompt.backgroundColor = colorAccent
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
        colorCardTextRead = ResourcesDay.CARD_TEXT_COLOR_READ
        
        self.view.backgroundColor = colorBackgroundMain
        self.collectionView?.backgroundColor = colorBackground
        self.collectionView?.backgroundColor = colorBackground
        if selectedFeed == "Subscriptions" {
            //            subscriptionsButton.tintColor = colorAccent
            subscriptionsButton.selectedImage?.sd_tintedImage(with: colorAccent)
        } else if selectedFeed == "Trending" {
            //            trendingButton.tintColor = colorAccent
            trendingButton.selectedImage?.sd_tintedImage(with: colorAccent)
        } else if selectedFeed == "Deals" {
            //            dealsButton.tintColor = colorAccent
            dealsButton.selectedImage?.sd_tintedImage(with: colorAccent)
            //        } else if selectedFeed == "Saved" {
            //            savedButton.tintColor = colorAccent
        }
        let colorScheme = MDCBasicColorScheme(primaryColor: colorAccent)
        MDCButtonColorThemer.apply(colorScheme, to: floatingButton)
        bottomBarView.barTintColor = colorBackgroundMain
        newContentPrompt.backgroundColor = colorAccent
    }
    
    func launchLogin() {
        let authViewController = FUIAuth.defaultAuthUI()?.authViewController()
        authViewController?.navigationBar.isHidden = true
        self.didLogin = true
        self.present(authViewController!, animated: true, completion: nil)
    }
    
    func setupUser() {
        
        if let currentUser = Auth.auth().currentUser  {
            self.user = currentUser
            self.uid = currentUser.uid
            
            Crashlytics.sharedInstance().setUserIdentifier(self.uid)
            
            self.loadNotifications()
            
            print("feedVC getUser:")
            dataSource.getUser(user: currentUser) { (retrievedUser) in
                if let retrievedUser = retrievedUser {
                    print("retrieved user")
                    currentUser.reload()
                    
                    // this is required as facebook users accounts are not automatically email verified
                    for userInfo in currentUser.providerData {
                        if userInfo.providerID == "facebook.com" {
                            self.globals.isUserEmailVerified = true
                            retrievedUser.isEmailVerified = true
                        }
                    }
                    
                    if (!currentUser.isEmailVerified && !retrievedUser.isEmailVerified) {
                        self.showEmailVerificationAlert(user: currentUser)
                    } else {
                        self.globals.isUserEmailVerified = true
                    }
                    
                    self.dataSource.getThemeSubscriptions(user: currentUser) { themePrefs in
                        self.themeKey = self.defaults.string(forKey: "themeKey")
                        self.themeFilters = self.defaults.stringArray(forKey: "themeFilters")
                        
                        // If user has no theme prefs, go to theme selection scene
                        
                        if self.themeKey == nil {
                            self.isFirstTimeLogin = true
                            self.performSegue(withIdentifier: "Edit Subscriptions", sender: self)
                        }
                        
                        retrievedUser.uid = self.uid ?? ""
                        retrievedUser.displayName = currentUser.displayName ?? ""
                        retrievedUser.token = self.token ?? ""
                        retrievedUser.email = currentUser.email ?? ""
                        if !retrievedUser.isEmailVerified { retrievedUser.isEmailVerified = self.globals.isUserEmailVerified }
                        retrievedUser.device = Device.current.description
                        retrievedUser.creationTimeStamp = (currentUser.metadata.creationDate?.timeIntervalSince1970 ?? 0) * 1000
                        retrievedUser.lastSignInTimeStamp = (currentUser.metadata.lastSignInDate?.timeIntervalSince1970 ?? 0) * 1000
                        retrievedUser.openedSinceLastReport = true
                        retrievedUser.targetPoints = max(10, retrievedUser.targetPoints)
                        
                        self.dataSource.updateUser(retrievedUser.toDictForUpdate())
                        
                        // remove old tokens from iPhoneUsers topic
                        Messaging.messaging().unsubscribe(fromTopic: "iPhoneUsers")
                        // subscribe to recommended articles push
                        let recArticlesPref = self.defaults.bool(forKey: "recArticlesNotifPref")
                        if recArticlesPref {
                            Messaging.messaging().subscribe(toTopic: "iPhoneRecArticlesPush")
                        }
                        // subscribe to recommended deals push
                        let recDealsPref = self.defaults.bool(forKey: "recDealsNotifPref")
                        if recDealsPref {
                            Messaging.messaging().subscribe(toTopic: "iPhoneRecDealsPush")
                        }
                        // subscribe to acorn for manual article push
                        Messaging.messaging().subscribe(toTopic: "acorn")
                        // subscribe to saved articles reminder push
                        let savedArticlesReminderPref = self.defaults.bool(forKey: "savedArticlesReminderNotifPref")
                        if savedArticlesReminderPref {
                            Messaging.messaging().subscribe(toTopic: "savedArticlesReminderPush")
                        }
                        
                        // highlight views
                        let hasSeenNearbyHighlight = self.defaults.bool(forKey: "seenNearbyHighlight")
                        let hasSeenSavedHighlight = self.defaults.bool(forKey: "seenSavedHighlight")
                        if (!hasSeenNearbyHighlight && !hasSeenSavedHighlight) {
                            self.highlightNearbyButton(onComplete: { self.highlightSaveButton(onComplete: {}) })
                        } else if (!hasSeenNearbyHighlight) {
                            self.highlightNearbyButton(onComplete: {})
                        }
                    
                        if let _ = self.user {
                            self.loadData()
                        } else {
                            self.logout()
                        }
                        
                        if retrievedUser.openedArticles.keys.count > 50 {
                            if !self.defaults.bool(forKey: "seenSurveyRequest") {
                                self.sendSurveyRequest(user: retrievedUser)
                                self.defaults.set(true, forKey: "seenSurveyRequest")
                            }
                        }
                        
                        // store saved items addresses on device
                        if let address = self.localDb.getFirstAddress() {
                            print("addressList: \(address)")
                        } else {
                            self.dataSource.getSavedItemsAddresses()
                        }
                        
                    }
                } else if retrievedUser == nil {
                    print("new user")
                    
                    // this is required as facebook users accounts are not automatically email verified
                    for userInfo in currentUser.providerData {
                        if userInfo.providerID == "facebook.com" {
                            self.globals.isUserEmailVerified = true
                        }
                    }
                    
                    let acornUser = AcornUser(uid: self.uid ?? "", displayName: currentUser.displayName ?? "", token: self.token ?? "", email: currentUser.email ?? "", isEmailVerified: self.globals.isUserEmailVerified, device: Device.current.description, creationTimeStamp: (currentUser.metadata.creationDate?.timeIntervalSince1970 ?? 0) * 1000, lastSignInTimeStamp: (currentUser.metadata.lastSignInDate?.timeIntervalSince1970 ?? 0) * 1000, openedSinceLastReport: true)
                    
                    if self.referredBy != nil { acornUser.referredBy = self.referredBy }
                    
                    self.dataSource.setUser(acornUser.toDict())
                    
                    // subscribe to recommended articles push
                    let recArticlesPref = self.defaults.bool(forKey: "recArticlesNotifPref")
                    if recArticlesPref {
                        Messaging.messaging().subscribe(toTopic: "iPhoneRecArticlesPush")
                    }
                    // subscribe to recommended deals push
                    let recDealsPref = self.defaults.bool(forKey: "recDealsNotifPref")
                    if recDealsPref {
                        Messaging.messaging().subscribe(toTopic: "iPhoneRecDealsPush")
                    }
                    // subscribe to acorn for manual article push
                    Messaging.messaging().subscribe(toTopic: "acorn")
                    // subscribe to saved articles reminder push
                    let savedArticlesReminderPref = self.defaults.bool(forKey: "savedArticlesReminderNotifPref")
                    if savedArticlesReminderPref {
                        Messaging.messaging().subscribe(toTopic: "savedArticlesReminderPush")
                    }
                    
                    self.isFirstTimeLogin = true
                    self.performSegue(withIdentifier: "Edit Subscriptions", sender: self)
                    return
                }
                
                do {
                    let reachability = try Reachability()
                    if reachability.connection == .wifi || reachability.connection == .cellular {
                        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
                        let lastDownloadArticlesTime = self.defaults.double(forKey: "lastDownloadArticlesTime")
    //                    let lastDownloadArticlesTime: Double = 0
                        print("lastDownloadArticlesTime: \(lastDownloadArticlesTime)")
                        if now > lastDownloadArticlesTime + 60 * 60 * 1000 { // 1 hour
                            let cutOffDate = now - 2 * 24 * 60 * 60 * 1000 // 2 days ago
                            self.dataSource.downloadSubscribedArticles() {
                                self.localDb.deleteOldArticles(cutOffDate: cutOffDate)
                                self.defaults.set(now, forKey: "lastDownloadArticlesTime")
                            }
                        }
                    }
                } catch let error {
                    print("unable to get connectivity: \(error)")
                }
            }
        } else {
            launchLogin()
            return
        }
    }
    
    func loadData() {
        showLoading()
        switch selectedFeed {
        case "Subscriptions":
            getSubscriptionsFeed()
        case "Trending":
            getTrendingFeed()
        case "Deals":
            getDealsFeed()
        case "Saved":
            getSavedFeed()
        case "Nearby":
            getNearbyFeed()
        case "FilteredTheme":
            getFilteredThemeFeed(theme: self.specificFeed)
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
    
    func sendSurveyRequest(user: AcornUser) {
        let firstName = user.displayName.split(separator: " ")[0]
        let ac = UIAlertController(title: "Help Shape the Future of Acorn!", message: "Thanks for supporting Acorn, \(firstName)! Having reached 50 articles read, we would love to hear your opinion on the app. Would you like to help improve Acorn?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
            self.dataSource.logSurveyResponse(false)
        }))
        ac.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            self.dataSource.logSurveyResponse(true)
            if let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSdrEHdVUB5M7ouMTihf5Y02yGhGytPK0-xjY427TcedfBMCBQ/viewform?usp=sf_link") {
                UIApplication.shared.open(url)
            }
        }))
        self.present(ac, animated: true, completion: nil)
    }
    
    @objc private func refreshOptions(sender: UIRefreshControl) {
        wasRefreshCalled = true
        reloadFeed()
        sender.endRefreshing()
    }
    
    private func reloadFeed() {
        resetView()
        loadData()
    }
    
    private func resetView() {
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
        
        if let bannerView = bannerView {
            bannerView.frame.origin.y = view.bounds.size.height - bottomBarView.frame.height - bannerView.frame.height
            
            collectionView.contentInset.bottom = bottomBarView.frame.height + bannerView.frame.height
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear")
        super.viewDidAppear(animated)
        
        if didLaunch || didLogin || subscriptionsDidChange {
            setupUser()
        } else {
            for article in self.articleList {
                if let article = article as? Article {
                    self.articleListIds.append(article.objectID)
                    
                    if article.type == "article" || article.type == "post" {
                        self.dataSource.observeSingleArticle(articleId: article.objectID) { (item) in
                            if let index = self.articleListIds.firstIndex(of: item.objectID) {
                                print("article returned for index \(index): \(item.objectID)")
                                self.articleList[index] = item
                                self.collectionView?.reloadData()
                            }
                        }
                    } else if article.type == "video" {
                        self.dataSource.observeSingleVideo(id: article.objectID) { video in
                            let convertedVideo = Article(video: video)
                            if let index = self.articleListIds.firstIndex(of: convertedVideo.objectID) {
                                print("video returned for index \(index): \(convertedVideo.objectID)")
                                self.articleList[index] = convertedVideo
                                self.collectionView?.reloadData()
                            }
                        }
                    }
                }
            }
            
            if selectedFeed == "Subscriptions" {
                bottomBarView.selectedItem = bottomBarView.items[0]
                dataSource.getSubscriptionsFeed() { (articles) in
                    if let currentFirstTenArticles = Array(self.articleList[0..<10]) as? [Article] {
                        var newFirstTenArticleIds = [String]()
                        for i in 0..<10 {
                            newFirstTenArticleIds.append(articles[i].objectID)
                        }
                        var diffCount = 0
                        for article in currentFirstTenArticles {
                            if !newFirstTenArticleIds.contains(article.objectID) {
                                diffCount += 1
                            }
                        }
                        
                        if diffCount > 5 {
                            self.hitsArticles = articles
                            let gesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapNewContentPrompt(_:)))
                            self.newContentPrompt.addGestureRecognizer(gesture)
                            self.newContentPrompt.isHidden = false
                        }
                    }
                }
            } else if selectedFeed == "Trending" {
                bottomBarView.selectedItem = bottomBarView.items[1]
                dataSource.getTrendingFeed() { (articles) in
                    if let currentFirstTenArticles = Array(self.articleList[0..<10]) as? [Article] {
                        var newFirstTenArticleIds = [String]()
                        for i in 0..<10 {
                            newFirstTenArticleIds.append(articles[i].objectID)
                        }
                        var diffCount = 0
                        for article in currentFirstTenArticles {
                            if !newFirstTenArticleIds.contains(article.objectID) {
                                diffCount += 1
                            }
                        }
                        
                        if diffCount > 5 {
                            self.hitsArticles = articles
                            let gesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapNewContentPrompt(_:)))
                            self.newContentPrompt.addGestureRecognizer(gesture)
                            self.newContentPrompt.isHidden = false
                        }
                    }
                }
            } else if selectedFeed == "Deals" {
                bottomBarView.selectedItem = bottomBarView.items[2]
                dataSource.getDealsFeed() { (articles) in
                    if let currentFirstTenArticles = Array(self.articleList[0..<10]) as? [Article] {
                        var newFirstTenArticleIds = [String]()
                        for i in 0..<10 {
                            newFirstTenArticleIds.append(articles[i].objectID)
                        }
                        var diffCount = 0
                        for article in currentFirstTenArticles {
                            if !newFirstTenArticleIds.contains(article.objectID) {
                                diffCount += 1
                            }
                        }
                        
                        if diffCount > 5 {
                            self.hitsArticles = articles
                            let gesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapNewContentPrompt(_:)))
                            self.newContentPrompt.addGestureRecognizer(gesture)
                            self.newContentPrompt.isHidden = false
                        }
                    }
                }
            } else if selectedFeed == "FilteredTheme" {
                if masterFeed == "Subscriptions" {
                    bottomBarView.selectedItem = bottomBarView.items[0]
                } else if masterFeed == "Trending" {
                    bottomBarView.selectedItem = bottomBarView.items[1]
                }
                guard let theme = self.specificFeed else { return }
                let themeKey = theme
                let themeFilter = "mainTheme: \"\(theme)\""
                dataSource.getFilteredThemeFeed(key: themeKey, filters: themeFilter) { (articles) in
                    if let currentFirstTenArticles = Array(self.articleList[0..<10]) as? [Article] {
                        var newFirstTenArticleIds = [String]()
                        for i in 0..<10 {
                            newFirstTenArticleIds.append(articles[i].objectID)
                        }
                        var diffCount = 0
                        for article in currentFirstTenArticles {
                            if !newFirstTenArticleIds.contains(article.objectID) {
                                diffCount += 1
                            }
                        }
                        
                        if diffCount > 5 {
                            self.hitsArticles = articles
                            let gesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapNewContentPrompt(_:)))
                            self.newContentPrompt.addGestureRecognizer(gesture)
                            self.newContentPrompt.isHidden = false
                        }
                    }
                }
            }
        }
        
        if defaults.bool(forKey: "locationNotifPref") {
            if CLLocationManager.locationServicesEnabled() {
                print("locations enabled")
                self.locationManager.delegate = self
                self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self.locationManager.startUpdatingLocation()
            } else {
                defaults.set(false, forKey: "locationNotifPref")
                dataSource.setLocationNotificationPreference(bool: false)
            }
        }
        
        // listener for premium status
        let now = Date().timeIntervalSince1970 * 1000.0
        if let user = Auth.auth().currentUser {
            print("observe user premium status")
            self.dataSource.getUserPremiumStatus(user) { (status) in
                if let end = status["end"] {
                    if end > now {
                        self.userButton.tintColor = UIColor(red: 48.0/255.0, green: 48.0/255.0, blue: 48.0/255.0, alpha: 1.0)
                        self.isUserPremium = true
                    }
                }
            }
        }
        
        MDCSnackbarManager.setBottomOffset(bottomBarView.frame.height)
        navigationItem.leftBarButtonItems?[0].accessibilityLabel = "Notifications"
        navigationItem.rightBarButtonItems?[0].accessibilityLabel = "More options"
        navigationItem.rightBarButtonItems?[1].accessibilityLabel = "Search articles"
    }
    
    func highlightSaveButton(onComplete: @escaping () -> ()) {
        let key = "seenSavedHighlight"
        if let view = self.saveButtonToHighlight {
            self.highlightView(view: view, title: "Save", content: "Too busy to read? Save articles for later! You can even get reminder notifications for events or deals a day before they happen!", defaultsKey: key, onComplete: onComplete)
        }
    }
    
    func highlightNearbyButton(onComplete: @escaping () -> ()) {
        let key = "seenNearbyHighlight"
        if let view = bottomBarView.view(for: nearbyButton) {
            self.highlightView(view: view, title: "Near Me", content: "Discover restaurants, events or deals near you! Refer a friend using the Share App Invite function in the top right menu to access this premium feature!", defaultsKey: key, onComplete: onComplete)
        }
    }
    
    func highlightView(view: UIView, title: String, content: String, defaultsKey: String, onComplete: @escaping () -> ()) {
        let highlightController = MDCFeatureHighlightViewController(highlightedView: view, completion: {(accepted: Bool) in
            self.defaults.set(true, forKey: defaultsKey)
            onComplete()
        })
        highlightController.titleText = title
        highlightController.bodyText = content
        highlightController.outerHighlightColor = colorAccent.withAlphaComponent(kMDCFeatureHighlightOuterHighlightAlpha)
        present(highlightController, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MDCSnackbarManager.setBottomOffset(0)
        self.clearLoading()
    }
    
    @objc func getSubscriptionsFeed() {
        self.view.makeToast("Subscriptions", point: toastPosition, title: nil, image: nil, completion: nil)
        if selectedFeed != "Subscriptions" || wasRefreshCalled || subscriptionsDidChange || didLogin {
            dataSource.removeFeedObservers()
            selectedFeed = "Subscriptions"
            feedDidChange = true
            self.newContentPrompt.isHidden = true
            
            dataSource.getSubscriptionsFeed() { (articles) in
                if self.didLaunch || self.feedDidChange {
                    self.getFeed(for: articles)
                    self.feedDidChange = false
                } else {
                    self.hitsArticles = articles
                    let gesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapNewContentPrompt(_:)))
                    self.newContentPrompt.addGestureRecognizer(gesture)
                    self.newContentPrompt.isHidden = false
                }
            }
        } else {
            self.clearLoading()
        }
    }
    
    func getMoreSubscriptionsFeed(startAt: String) {
        if selectedFeed != "Subscriptions" { return }
        let initialList = self.articleList
        
        dataSource.getSubscriptionsFeed(startAt: startAt) { (articles) in
            var combinedList = Array(initialList.dropLast())
            combinedList.append(contentsOf: articles)
            self.articleList = combinedList
            
            self.collectionView?.reloadData()
            self.collectionViewLayout.invalidateLayout()
            self.clearLoading()
        }
    }
    
    @objc func getTrendingFeed() {
        self.view.makeToast("Trending", point: toastPosition, title: nil, image: nil, completion: nil)
        if selectedFeed != "Trending" || wasRefreshCalled {
            dataSource.removeFeedObservers()
            selectedFeed = "Trending"
            feedDidChange = true
            self.newContentPrompt.isHidden = true
            
            dataSource.getTrendingFeed() { (articles) in
                if self.didLaunch || self.feedDidChange {
                    self.getFeed(for: articles)
                    self.feedDidChange = false
                } else {
                    self.hitsArticles = articles
                    let gesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapNewContentPrompt(_:)))
                    self.newContentPrompt.addGestureRecognizer(gesture)
                    self.newContentPrompt.isHidden = false
                }
            }
        } else {
            self.clearLoading()
        }
    }
    
    func getMoreTrendingFeed(startAt: String) {
        if selectedFeed != "Trending" { return }
        let initialList = self.articleList
        
        dataSource.getTrendingFeed(startAt: startAt) { (articles) in
            var combinedList = Array(initialList.dropLast())
            combinedList.append(contentsOf: articles)
            self.articleList = combinedList
            
            self.collectionView?.reloadData()
            self.collectionViewLayout.invalidateLayout()
            self.clearLoading()
        }
    }
    
    @objc func getDealsFeed() {
        self.view.makeToast("Deals", point: toastPosition, title: nil, image: nil, completion: nil)
        if selectedFeed != "Deals" || wasRefreshCalled {
            dataSource.removeFeedObservers()
            selectedFeed = "Deals"
            feedDidChange = true
            self.newContentPrompt.isHidden = true
            
            dataSource.getDealsFeed() { (articles) in
                if self.didLaunch || self.feedDidChange {
                    self.getFeed(for: articles)
                    self.feedDidChange = false
                } else {
                    self.hitsArticles = articles
                    let gesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapNewContentPrompt(_:)))
                    self.newContentPrompt.addGestureRecognizer(gesture)
                    self.newContentPrompt.isHidden = false
                }
            }
        } else {
            self.clearLoading()
        }
    }
    
    func getMoreDealsFeed(startAt: String) {
        if selectedFeed != "Deals" { return }
        let initialList = self.articleList
        
        dataSource.getDealsFeed(startAt: startAt) { (articles) in
            var combinedList = Array(initialList.dropLast())
            combinedList.append(contentsOf: articles)
            self.articleList = combinedList
            
            self.collectionView?.reloadData()
            self.collectionViewLayout.invalidateLayout()
            self.clearLoading()
        }
    }
    
    @objc func didTapNewContentPrompt(_ sender: UITapGestureRecognizer) {
        getFeed(for: self.hitsArticles)
        newContentPrompt.isHidden = true
    }
    
    func getFeed(for articles: [Article]) {
        print("articlesCount: \(articles.count)")
        removeArticleObservers()
        self.articleList.removeAll()
        self.articleListIds.removeAll()
        self.articleList.append(contentsOf: articles)
        
        let showVideos = self.defaults.bool(forKey: "videosInFeedPref")
        print("showVideos: \(showVideos)")
        if showVideos {
            let channelsToRemove = self.defaults.array(forKey: "videosInFeedChannelsToRemove") as? [String] ?? [String]()
            
            self.dataSource.getVideosForMainFeed { (videos) in
                var themes = [String]()
                if self.selectedFeed == "Subscriptions" {
                    themes = self.defaults.string(forKey: "themeKey")?.components(separatedBy: "_") ?? ResourcesDay.THEME_LIST.sorted()
                } else if self.selectedFeed == "Trending" {
                    themes = ResourcesDay.THEME_LIST.sorted()
                } else if self.selectedFeed == "Deals" {
                    themes = ["Deals"]
                } else if self.selectedFeed == "FilteredTheme" {
                    guard let theme = self.specificFeed else { return }
                    themes = [theme]
                }
                for video in videos {
                    if let source = video.source, let theme = video.mainTheme {
                        if !channelsToRemove.contains(source) && themes.contains(theme) {
                            self.videoList.append(video)
                        }
                    }
                }
                self.videoList.shuffle()
                
                let sizeLimit = min(self.articleList.count / 5, self.videoList.count)
                for i in 0..<sizeLimit {
                    let videoToInsert = Article(video: self.videoList[i])
                    self.articleList.insert(videoToInsert, at: (i+1)*5)
                }
                
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    self.collectionViewLayout.invalidateLayout()
                    self.clearLoading()
                    self.subscriptionsDidChange = false
                    self.didLogin = false
                    self.isFirstTimeLogin = false
                    self.wasRefreshCalled = false
                    self.didLaunch = false
                }
                
                for article in self.articleList {
                    if let article = article as? Article {
                        self.articleListIds.append(article.objectID)
                        
                        if article.type == "article" || article.type == "post" {
                            self.dataSource.observeSingleArticle(articleId: article.objectID) { (item) in
                                if let index = self.articleListIds.firstIndex(of: item.objectID) {
                                    if index < self.articleList.count {
                                        print("article returned for index \(index): \(item.objectID)")
                                        self.articleList[index] = item
                                        self.collectionView?.reloadData()
                                    }
                                }
                            }
                        } else if article.type == "video" {
                            self.dataSource.observeSingleVideo(id: article.objectID) { video in
                                let convertedVideo = Article(video: video)
                                if let index = self.articleListIds.firstIndex(of: convertedVideo.objectID) {
                                    if index < self.articleList.count {
                                        print("video returned for index \(index): \(convertedVideo.objectID)")
                                        self.articleList[index] = convertedVideo
                                        self.collectionView?.reloadData()
                                    }
                                }
                            }
                        }
                    }
                }
                
                self.loadAds()
            }
        } else {
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                self.collectionViewLayout.invalidateLayout()
                self.clearLoading()
                self.subscriptionsDidChange = false
                self.didLogin = false
                self.isFirstTimeLogin = false
                self.wasRefreshCalled = false
                self.didLaunch = false
            }
                
            for article in self.articleList {
                if let article = article as? Article {
                    self.articleListIds.append(article.objectID)
                    self.dataSource.observeSingleArticle(articleId: article.objectID) { (item) in
                        if let index = self.articleListIds.firstIndex(of: item.objectID) {
                            if index < self.articleList.count {
                                self.articleList[index] = item
                                self.collectionView?.reloadData()
                            }
                        }
                    }
                }
            }
            
            self.loadAds()
        }
    }
    
    func getFilteredThemeFeed(theme: String?) {
        if selectedFeed != "Deals" || wasRefreshCalled {
            if let theme = theme {
                self.view.makeToast(theme, point: toastPosition, title: nil, image: nil, completion: nil)
                self.masterFeed = self.selectedFeed
                dataSource.removeFeedObservers()
                self.selectedFeed = "FilteredTheme"
                self.specificFeed = theme
                
                let themeKey = theme
                let themeFilter = "mainTheme: \"\(theme)\""
                dataSource.getFilteredThemeFeed(key: themeKey, filters: themeFilter) { (articles) in
                    if self.didLaunch {
                        self.getFeed(for: articles)
                    } else {
                        self.hitsArticles = articles
                        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapNewContentPrompt(_:)))
                        self.newContentPrompt.addGestureRecognizer(gesture)
                        self.newContentPrompt.isHidden = false
                    }
                }
            }
        } else {
            self.clearLoading()
        }
    }
    
    func getMoreFilteredThemeFeed(startAt: String, key: String?) {
        if selectedFeed != "FilteredTheme" { return }
        if let key = key {
            let initialList = self.articleList
            
            dataSource.getFilteredThemeFeed(startAt: startAt, key: key) { (articles) in
                var combinedList = Array(initialList.dropLast())
                combinedList.append(contentsOf: articles)
                self.articleList = combinedList
                
                self.collectionView?.reloadData()
                self.collectionViewLayout.invalidateLayout()
                self.clearLoading()
            }
        }
    }
    
    @objc func getSavedFeed() {
        self.view.makeToast("Saved Articles", point: toastPosition, title: nil, image: nil, completion: nil)
        if selectedFeed != "Saved" || wasRefreshCalled {
            dataSource.getSavedFeed() { (articles) in
                var articleList = [Article]()
                articleList.append(contentsOf: articles)
                articleList.sort(by: { (o1, o2) -> Bool in
                    if let uid = self.uid {
                        let saveDate1 = o1.savers?[uid] ?? 0
                        let saveDate2 = o2.savers?[uid] ?? 0
                        return saveDate2 < saveDate1
                    }
                    return true
                })
                self.savedArticleList = articleList
                
                self.clearLoading()
                
                self.performSegue(withIdentifier: "Saved Articles", sender: self)
            }
        } else {
            self.clearLoading()
        }
    }
    
    @objc func getNearbyFeed() {
        self.view.makeToast("Nearby", point: toastPosition, title: nil, image: nil, completion: nil)
        if selectedFeed != "Nearby" {
            self.clearLoading()
            self.performSegue(withIdentifier: "Nearby", sender: self)
        } else {
            self.clearLoading()
        }
    }
    
    @objc func getVideoFeed() {
        self.view.makeToast("Videos", point: toastPosition, title: nil, image: nil, completion: nil)
        self.performSegue(withIdentifier: "Videos", sender: self)
    }
    
//    func resetButtonTints() {
//        self.subscriptionsButton.tintColor = UIColor.lightGray
//        self.dealsButton.tintColor = UIColor.lightGray
//        self.trendingButton.tintColor = UIColor.lightGray
//        self.savedButton.tintColor = UIColor.lightGray
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Create Post" {
            let vc = segue.destination as! CreatePostViewController
            vc.delegate = self
        } else if segue.identifier == "Edit Subscriptions" {
            let vc = segue.destination as! SubscriptionsViewController
            vc.isFirstTimeLogin = self.isFirstTimeLogin
            vc.vc = self
        } else if segue.identifier == "Notifications" {
            
        } else if segue.identifier == "User" {
            let vc = segue.destination as! UserViewController
            vc.user = self.acornUser
        } else if segue.identifier == "Saved Articles" {
            let vc = segue.destination as! SavedArticlesViewController
            vc.savedList = self.savedArticleList
        } else if segue.identifier == "Videos" {
        }
    }
    
    @objc private func didTapFloatingButton() {
        if let user = user {
            if user.isEmailVerified {
                performSegue(withIdentifier: "Create Post", sender: self)
            } else {
                let toastMessage = "Please verify your email before posting!"
                self.view.makeToast(toastMessage, point: toastPosition, title: nil, image: nil, completion: nil)
            }
        }
    }
    
    @IBAction func didTapSearch(_ sender: Any) {
//        performSegue(withIdentifier: "Search", sender: self)
        self.dataSource.getAlgoliaApiKey() { key in
            let vc = SearchViewController(algoliaApiKey: key)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func didTapNavBarTitle(_ sender: Any) {
        let dropdown = DropDown()
        let subscribedThemes = self.defaults.string(forKey: "themeKey")?.components(separatedBy: "_") ?? ResourcesDay.THEME_LIST.sorted()
        let themeList = ResourcesDay.THEME_LIST.sorted()
        dropdown.anchorView = self.navBarTitleButton
        
        switch self.selectedFeed {
        case "Subscriptions":
            dropdown.dataSource = subscribedThemes
        case "Trending":
            dropdown.dataSource = themeList
        case "Deals":
            return
        default:
            dropdown.dataSource = subscribedThemes
        }
        
        dropdown.width = 200
        dropdown.direction = .bottom
        dropdown.backgroundColor = nightModeOn ? ResourcesNight.OPTIONS_BG_COLOR : ResourcesDay.OPTIONS_BG_COLOR
        dropdown.textColor = nightModeOn ? ResourcesNight.OPTIONS_TEXT_COLOR : ResourcesDay.OPTIONS_TEXT_COLOR
        dropdown.bottomOffset = CGPoint(x: 0, y: (dropdown.anchorView?.plainView.bounds.height)!)
        dropdown.selectionAction = { (index: Int, item: String) in
            switch self.masterFeed {
            case "Subscriptions":
                self.getFilteredThemeFeed(theme: subscribedThemes[index])
            case "Trending":
                self.getFilteredThemeFeed(theme: themeList[index])
            default:
                self.getFilteredThemeFeed(theme: subscribedThemes[index])
            }
        }
        dropdown.show()
    }
    
   
    @IBAction func didTapMoreOptions(_ sender: Any) {
        let dropdown = DropDown()
        dropdown.anchorView = moreOptionsButton
        dropdown.dataSource = ["Edit Subscriptions", "Settings", "Log Out", "Share App Invite"]//, "Saved Articles Reminder Push", "Recommended Deals Push", "Recommended Articles Push"]
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
                    self.logout()
                }))
                self.present(ac, animated: true, completion: nil)
            } else if item == "Share App Invite" {
                InviteUtils.createShortDynamicLink(uid: self.uid!, onComplete: { (link) in
                    let shareText = "Don't miss out on the latest news, deals, events and life hacks! Download Acorn: Blogs in a Nutshell now!"
                    let shareUrl = URL(string: link)
                    let shareItems = [shareText, shareUrl ?? ""] as [Any]
                    let activityController = UIActivityViewController(activityItems: shareItems,  applicationActivities: nil)
                    DispatchQueue.main.async {
                        self.present(activityController, animated: true)
                    }
                })
            } else if item == "Recommended Articles Push" {
                let recArticlesPref = self.defaults.bool(forKey: "recArticlesNotifPref")
                print("recArticlesPref: \(recArticlesPref)")
                if recArticlesPref {
//                    let waitTime = Double(arc4random_uniform(10))
//                    print("waitTime: \(waitTime)")

                    //DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                        print("recArticlesPush started")
                        self.appDelegate.scheduleRecommendedArticlesPush() {
                            print("recArticlesPush completed")
                            self.appDelegate.updateNotificationsBadge(notificationsButton: self.notificationsButton)
                        }
                    //}
                }
            } else if item == "Recommended Deals Push" {
                let recDealsPref = self.defaults.bool(forKey: "recDealsNotifPref")
                print("recDealsPref: \(recDealsPref)")
                if recDealsPref {
                    let waitTime = Double(arc4random_uniform(10))
                    print("waitTime: \(waitTime)")

                    DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                        print("recDealsPush started")
                        self.appDelegate.scheduleRecommendedDealsPush() {
                            print("recDealsPush completed")
                            self.appDelegate.updateNotificationsBadge(notificationsButton: self.notificationsButton)
                        }
                    }
                }
            } else if item == "Saved Articles Reminder Push" {
                let savedArticlesReminderPref = self.defaults.bool(forKey: "savedArticlesReminderNotifPref")
                print("savedArticlesReminderPref: \(savedArticlesReminderPref)")
                if savedArticlesReminderPref {
                    let waitTime = Double(arc4random_uniform(10))
                    print("waitTime: \(waitTime)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                        print("savedArticlesReminderPush started")
                        self.appDelegate.scheduleSavedArticlesReminderPush() {
                            print("savedArticlesReminderPush completed")
                            self.appDelegate.updateNotificationsBadge(notificationsButton: self.notificationsButton)
                        }
                    }
                }
            }
        }
        dropdown.show()
    }
    
    @IBAction func didTapUserButton(_ sender: Any) {
        if let user = Auth.auth().currentUser {
            dataSource.getUser(user: user) { (acornUser) in
                self.acornUser = acornUser
                self.performSegue(withIdentifier: "User", sender: self)
            }
        }
    }
    
    
    @IBAction func didTapNotifications(_ sender: Any) {
        performSegue(withIdentifier: "Notifications", sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func logout() {
        self.dataSource.removePremiumStatusObserver()
        do {
            try Auth.auth().signOut()
        } catch {
            print("error logging out")
        }
        self.resetView()
        self.removeArticleObservers()
        self.selectedFeed = nil
        self.userButton.tintColor = .white
        self.isUserPremium = false
        self.launchLogin()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("viewDidDisappear")
        if let _ = Auth.auth().currentUser {
            self.dataSource.removePremiumStatusObserver()
        }
        dataSource.removeFeedObservers()
        
        removeArticleObservers()
        
        for id in seenList.keys {
            dataSource.logSeenItemEvent(uid: uid!, itemId: id, type: seenList[id]!)
        }
        seenList.removeAll()
    }
    
    func removeArticleObservers() {
        // remove all observers for previous article list
        for article in self.articleList {
            if let article = article as? Article {
                if article.type == "article" || article.type == "post" {
                    self.dataSource.removeArticleObserver(article.objectID)
                } else if article.type == "video" {
                    self.dataSource.removeVideoObserver(article.objectID)
                }
            }
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return articleList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let article = articleList[indexPath.item] as? Article {
            if article.type == "video" {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoMainFeedCvCell", for: indexPath) as! VideoFeedCvCell
                cell.delegate = self
                let video = Video(article: article)
                cell.video = video
                cell.textColor = colorCardText
                cell.textColorFaint = colorCardTextFaint
                cell.textColorRead = colorCardTextRead
                if let uid = self.uid {
                    cell.uid = uid
                } else {
                    cell.uid = "unknown"
                }
                
                cell.backgroundColor = colorCardBackground
                
                cell.sourceLabelWidthConstraint.constant = cellWidth!*7/24
                
                // get saveButton for highlighting
                if indexPath.item == 0 {
                    self.saveButtonToHighlight = cell.saveButton
                }
                
                cell.populateCell(video: video)
                return cell
            } else if article.type == "post" {
                if (article.link != nil && article.link != "") {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellPostWithArticle", for: indexPath) as! FeedCvCellPostWithArticle
                    cell.delegate = self
                    cell.article = article
                    cell.textColor = colorCardText
                    cell.textColorFaint = colorCardTextFaint
                    if let uid = self.uid {
                        cell.uid = uid
                    } else {
                        cell.uid = "unknown"
                    }
                    
                    cell.backgroundColor = colorCardBackground
                    
                    cell.sourceLabelWidthConstraint.constant = cellWidth!/3
                    
                    // get saveButton for highlighting
                    if indexPath.item == 0 {
                        self.saveButtonToHighlight = cell.saveButton
                    }
                    
                    cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                    return cell
                } else {
                    if (article.postImageUrl != nil && article.postImageUrl != "") {
                        if (article.title != article.postText) {
                            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellPostWithArticle", for: indexPath) as! FeedCvCellPostWithArticle
                            cell.delegate = self
                            cell.article = article
                            cell.textColor = colorCardText
                            cell.textColorFaint = colorCardTextFaint
                            cell.textColorRead = colorCardTextRead
                            if let uid = self.uid {
                                cell.uid = uid
                            } else {
                                cell.uid = "unknown"
                            }
                            
                            cell.backgroundColor = colorCardBackground
                            
                            cell.sourceLabelWidthConstraint.constant = cellWidth!/3
                            
                            // get saveButton for highlighting
                            if indexPath.item == 0 {
                                self.saveButtonToHighlight = cell.saveButton
                            }
                            
                            cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                            return cell
                        } else {
                            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellPost", for: indexPath) as! FeedCvCellPost
                            cell.delegate = self
                            cell.article = article
                            cell.textColor = colorCardText
                            cell.textColorFaint = colorCardTextFaint
                            cell.textColorRead = colorCardTextRead
                            if let uid = self.uid {
                                cell.uid = uid
                            } else {
                                cell.uid = "unknown"
                            }
                            
                            cell.backgroundColor = colorCardBackground
                            
                            cell.sourceLabelWidthConstraint.constant = cellWidth!/3
                            
                            // get saveButton for highlighting
                            if indexPath.item == 0 {
                                self.saveButtonToHighlight = cell.saveButton
                            }
                            
                            cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                            return cell
                        }
                    } else {
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellPostNoImage", for: indexPath) as! FeedCvCellPostNoImage
                        cell.delegate = self
                        cell.article = article
                        cell.textColor = colorCardText
                        cell.textColorFaint = colorCardTextFaint
                        cell.textColorRead = colorCardTextRead
                        if let uid = self.uid {
                            cell.uid = uid
                        } else {
                            cell.uid = "unknown"
                        }
                        
                        cell.backgroundColor = colorCardBackground
                        
                        cell.sourceLabelWidthConstraint.constant = cellWidth!/3
                        
                        // get saveButton for highlighting
                        if indexPath.item == 0 {
                            self.saveButtonToHighlight = cell.saveButton
                        }
                        
                        cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                        return cell
                    }
                }
            } else {
                if (article.imageUrl != nil && article.imageUrl != "") {
                    if (article.duplicates?.count ?? 0 > 0) {
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellWithDuplicates", for: indexPath) as! FeedCvCellWithDuplicates
                        cell.delegate = self
                        cell.article = article
                        cell.textColor = colorCardText
                        cell.textColorFaint = colorCardTextFaint
                        cell.textColorRead = colorCardTextRead
                        if let uid = self.uid {
                            cell.uid = uid
                        } else {
                            cell.uid = "unknown"
                        }
                        
                        cell.backgroundColor = colorCardBackground
                        
                        cell.sourceLabelWidthConstraint.constant = cellWidth!*7/24
                        
                        // get saveButton for highlighting
                        if indexPath.item == 0 {
                            self.saveButtonToHighlight = cell.saveButton
                        }
                        
                        cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                        return cell
                    } else {
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCell", for: indexPath) as! FeedCvCell
                        cell.delegate = self
                        cell.article = article
                        cell.textColor = colorCardText
                        cell.textColorFaint = colorCardTextFaint
                        cell.textColorRead = colorCardTextRead
                        if let uid = self.uid {
                            cell.uid = uid
                        } else {
                            cell.uid = "unknown"
                        }
                        
                        cell.backgroundColor = colorCardBackground
                        
                        cell.sourceLabelWidthConstraint.constant = cellWidth!*7/24
                        
                        // get saveButton for highlighting
                        if indexPath.item == 0 {
                            self.saveButtonToHighlight = cell.saveButton
                        }
                        
                        cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                        return cell
                    }
                } else {
                    if (article.duplicates!.count > 0) {
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellNoImageWithDuplicates", for: indexPath) as! FeedCvCellNoImageWithDuplicates
                        cell.delegate = self
                        cell.article = article
                        cell.textColor = colorCardText
                        cell.textColorFaint = colorCardTextFaint
                        cell.textColorRead = colorCardTextRead
                        if let uid = self.uid {
                            cell.uid = uid
                        } else {
                            cell.uid = "unknown"
                        }
                        
                        cell.backgroundColor = colorCardBackground
                        
                        cell.sourceLabelWidthConstraint.constant = cellWidth!/3
                        
                        // get saveButton for highlighting
                        if indexPath.item == 0 {
                            self.saveButtonToHighlight = cell.saveButton
                        }
                        
                        cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                        return cell
                    } else {
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellNoImage", for: indexPath) as! FeedCvCellNoImage
                        cell.delegate = self
                        cell.article = article
                        cell.textColor = colorCardText
                        cell.textColorFaint = colorCardTextFaint
                        cell.textColorRead = colorCardTextRead
                        if let uid = self.uid {
                            cell.uid = uid
                        } else {
                            cell.uid = "unknown"
                        }
                        
                        cell.backgroundColor = colorCardBackground
                        
                        cell.sourceLabelWidthConstraint.constant = cellWidth!/3
                        
                        // get saveButton for highlighting
                        if indexPath.item == 0 {
                            self.saveButtonToHighlight = cell.saveButton
                        }
                        
                        cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                        return cell
                    }
                }
            }
        } else {
            let nativeAd = articleList[indexPath.item] as! FBNativeAd
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NativeAdCvCell", for: indexPath) as! NativeAdCvCell
            cell.textColor = colorCardText
            cell.textColorFaint = colorCardTextFaint
            cell.backgroundColor = colorCardBackground
            cell.vc = self
            cell.populateContent(ad: nativeAd)
            return cell
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellHeightAt indexPath: IndexPath) -> CGFloat {
        if let article = articleList[indexPath.item] as? Article {
        
            if selectedFeed == "Saved" {
                return 138
            }
            
            let cellDefaultHeight: CGFloat = 116
            let imageHeight = self.cellWidth! / 16.0 * 9.0
            let duplicatesCvHeight: CGFloat = 8 + 131
            
            if article.type == "article" || article.type == "video" {
                let tempTitleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.cellWidth! - 24, height: CGFloat.greatestFiniteMagnitude))
                tempTitleLabel.numberOfLines = 0
                tempTitleLabel.lineBreakMode = .byWordWrapping
                tempTitleLabel.font = UIFont.systemFont(ofSize: 18.0)
                tempTitleLabel.text = article.title
                tempTitleLabel.sizeToFit()
                let titleHeight = tempTitleLabel.frame.height
                
                if article.type == "video" {
                    return cellDefaultHeight + titleHeight + imageHeight
                }
                
                if (article.imageUrl != nil && article.imageUrl != "") {
                    if (article.duplicates?.count ?? 0 > 0) {
                        return cellDefaultHeight + titleHeight + imageHeight + duplicatesCvHeight
                    } else {
                        return cellDefaultHeight + titleHeight + imageHeight
                    }
                } else {
                    if (article.duplicates?.count ?? 0 > 0) {
                        return cellDefaultHeight + titleHeight + duplicatesCvHeight
                    } else {
                        return cellDefaultHeight + titleHeight
                    }
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
        } else {
            let cellDefaultHeight: CGFloat = 79
            let imageHeight = self.cellWidth! / 16.0 * 9.0
            
            let nativeAd = articleList[indexPath.item] as! FBNativeAd
            let headline = nativeAd.headline ?? ""
            let body = nativeAd.bodyText ?? ""
            var bodyText = headline
            if body.count > headline.count { bodyText = body }
            
            let tempBodyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.cellWidth! - 24, height: CGFloat.greatestFiniteMagnitude))
            tempBodyLabel.numberOfLines = 0
            tempBodyLabel.lineBreakMode = .byWordWrapping
            tempBodyLabel.font = UIFont.systemFont(ofSize: 18.0)
            tempBodyLabel.text = bodyText
            tempBodyLabel.sizeToFit()
            let bodyHeight = tempBodyLabel.frame.height
            
            return cellDefaultHeight + bodyHeight + imageHeight
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            let hasSeenNearbyHighlight = self.defaults.bool(forKey: "seenNearbyHighlight")
            let hasSeenSavedHighlight = self.defaults.bool(forKey: "seenSavedHighlight")
            if (!hasSeenSavedHighlight && hasSeenNearbyHighlight) {
                highlightSaveButton(onComplete: {})
            }
        }
        
//        if indexPath.item == (self.articleList.count - self.loadTrigger) {
//            let lastArticle = articleList.last
//            switch selectedFeed {
//            case "Subscriptions":
//                getMoreSubscriptionsFeed(startAt: (lastArticle?.trendingIndex)!)
//            case "Trending":
//                getMoreTrendingFeed(startAt: (lastArticle?.trendingIndex)!)
//            case "Deals":
//                getMoreDealsFeed(startAt: (lastArticle?.trendingIndex)!)
//            case "FilteredTheme":
//                getMoreFilteredThemeFeed(startAt: (lastArticle?.trendingIndex)!, key: self.specificFeed)
//            default: break
//
//            }
//        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item < articleList.count {
            if let article = articleList[indexPath.item] as? Article {
    //            print("endDisplay: \(indexPath.item), id: \(article.objectID), title: \(article.title)")
                if !seenList.keys.contains(article.objectID) {
        //            dataSource.logSeenItemEvent(uid: uid!, itemId: article.objectID, type: article.type)
                    seenList[article.objectID] = article.type
                }
            }
        }
    }
    
    func showLoading() {
        self.collectionView?.isHidden = true
        self.spinner = displaySpinner()
    }
    
    func clearLoading() {
        if let spinner = self.spinner { self.removeSpinner(spinner) }
        self.collectionView?.isHidden = false
    }
    
    func region(location: CLLocation, radius: Double, id: String) -> CLCircularRegion {
        let region = CLCircularRegion(center: location.coordinate, radius: radius, identifier: id)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
    
    func startMonitoring(region: CLRegion) {
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            showAlert(title: nil, message: "Sorry, your device does not support location based services")
        }
        
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            showAlert(title: nil, message: "Acorn requires \"Always Available\" location access to provide you with location based notifications")
        }
        
        locationManager.startMonitoring(for: region)
        print("monitoring: \(region)")
    }
    
    func stopMonitoring(region: CLRegion) {
        for reg in locationManager.monitoredRegions {
            if reg.identifier == region.identifier {
                locationManager.stopMonitoring(for: reg)
                print("stop monitoring: \(region)")
            }
        }
    }
    
    func getNearestLocales(from: CLLocation, limit: Int, onComplete: @escaping ([(key: String, value: [String: Any])]) -> ()) {
        getMrtStationMap { (mrtStationMap) in
            var distanceFrom = [String: [String: Any]]()
            for station in mrtStationMap {
                let lat = station.value["latitude"] as? Double
                let lng = station.value["longitude"] as? Double
                if let lat = lat, let lng = lng {
                    let loc = CLLocation(latitude: lat, longitude: lng)
                    let distance = loc.distance(from: from)
                    distanceFrom[station.key] = ["location": loc, "distance": distance]
                }
            }
            let sortedDistanceFrom = distanceFrom.sorted(by: { ($0.value["distance"]! as! Double) < ($1.value["distance"]! as! Double) })
            let cutoff = min(sortedDistanceFrom.count, limit)
            let result = Array(sortedDistanceFrom[..<cutoff])
            onComplete(result)
        }
    }
    
    func getNearestSavedAddresses(from: CLLocation, limit: Int, onComplete: @escaping ([(key: String, value: [String: Any])]) -> ()) {
        if let addresses = localDb.getAllAddresses() {
            var distanceFrom = [String: [String: Any]]()
            for address in addresses {
                let addressLoc = CLLocation(latitude: address.latitude, longitude: address.longitude)
                let distance = addressLoc.distance(from: from)
                if let loc = distanceFrom[address.articleId], let currentDistance = loc["distance"] as? Double {
                    if currentDistance > distance {
                        distanceFrom[address.articleId] = ["location": addressLoc, "distance": distance]
                    }
                } else {
                    distanceFrom[address.articleId] = ["location": addressLoc, "distance": distance]
                }
            }
            let sortedDistanceFrom = distanceFrom.sorted(by: { ($0.value["distance"]! as! Double) < ($1.value["distance"]! as! Double) })
            let cutoff = min(sortedDistanceFrom.count, limit)
            let result = Array(sortedDistanceFrom[..<cutoff])
            print("distance: \(result)")
            onComplete(result)
        }
    }
    
    func getMrtStationMap(onComplete: @escaping ([String: [String: Any]]) -> ()) {
        if let mrtStationMap = defaults.object(forKey: "mrtStations") as? [String: [String: Any]] {
            onComplete(mrtStationMap)
        } else {
            dataSource.getMrtStations { (mrtStationMap) in
                self.defaults.set(mrtStationMap, forKey: "mrtStations")
                onComplete(mrtStationMap)
            }
        }
    }
}

extension FeedViewController: FeedCvCellDelegate {
    
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
    
    func openShareActivity(_ urlLink: String?, _ article: Article) {
        if let shareLink = urlLink {
            let shareText = "Shared using Acorn"
            let shareUrl = URL(string: shareLink)
            let shareItems = [shareText, shareUrl ?? ""] as [Any]
            
            Analytics.logEvent(AnalyticsEventShare, parameters: [
                AnalyticsParameterItemID: article.objectID,
                AnalyticsParameterItemCategory: article.mainTheme ?? "",
                "item_source": article.source ?? "",
                AnalyticsParameterContentType: article.type
            ])
            
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
    
    func upvoteActionTapped(article: Article, upvoteButton: UIButton, downvoteButton: UIButton) {
        if !isUserEmailVerified() {
            showEmailVerificationAlert(user: self.user!)
            return
        }
        
        upvoteButton.isEnabled = false
        downvoteButton.isEnabled = false
        
        var wasUpvoted = false
        var wasDownvoted = false
        
        if let upvoters = article.upvoters {
            if upvoters.keys.contains(self.uid!) {
                wasUpvoted = true
            }
        }
        
        if let downvoters = article.downvoters {
            if downvoters.keys.contains(self.uid!) {
                wasDownvoted = true
            }
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dataSource.updateArticleVote(article: article, actionIsUpvote: true, wasUpvoted: wasUpvoted, wasDownvoted: wasDownvoted) { dispatchGroup.leave() }
        
        dispatchGroup.enter()
        dataSource.updateUserVote(article: article, actionIsUpvote: true) { (userStatus) in
            if let userStatus = userStatus {
                let toastMessage = "Congratulations! You have grown into a \(userStatus)"
                self.view.makeToast(toastMessage, point: self.toastPosition, title: nil, image: nil, completion: nil)
            }
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            
            upvoteButton.isEnabled = true
            downvoteButton.isEnabled = true
        }
    }
    
    func downvoteActionTapped(article: Article, upvoteButton: UIButton, downvoteButton: UIButton) {
        if !isUserEmailVerified() {
            showEmailVerificationAlert(user: self.user!)
            return
        }
        
        upvoteButton.isEnabled = false
        downvoteButton.isEnabled = false
        
        var wasUpvoted = false
        var wasDownvoted = false
        
        if let upvoters = article.upvoters {
            if upvoters.keys.contains(self.uid!) {
                wasUpvoted = true
            }
        }
        
        if let downvoters = article.downvoters {
            if downvoters.keys.contains(self.uid!) {
                wasDownvoted = true
            }
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dataSource.updateArticleVote(article: article, actionIsUpvote: false, wasUpvoted: wasUpvoted, wasDownvoted: wasDownvoted) { dispatchGroup.leave() }
        
        dispatchGroup.enter()
        dataSource.updateUserVote(article: article, actionIsUpvote: false) { (userStatus) in
            if let userStatus = userStatus {
                let toastMessage = "Congratulations! You have grown into a \(userStatus)"
                self.view.makeToast(toastMessage, point: self.toastPosition, title: nil, image: nil, completion: nil)
            }
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            
            upvoteButton.isEnabled = true
            downvoteButton.isEnabled = true
        }
    }
 
    func saveActionTapped(article: Article, saveButton: UIButton) {
        saveButton.isEnabled = false
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dataSource.updateArticleSave(article: article) { dispatchGroup.leave() }
        
        dispatchGroup.enter()
        dataSource.updateUserSave(article: article) { dispatchGroup.leave() }
        
        dispatchGroup.notify(queue: .main) {
            saveButton.isEnabled = true
        }
    }
}

extension FeedViewController: VideoFeedCvCellDelegate {
    
    func openVideo(_ video: Video) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "YTPlayer") as? YTPlayerViewController
        vc?.videoId = String(video.objectID.suffix(11))
        PIPKit.show(with: vc!)
    }
    
    func openShareActivity(_ urlLink: String?, _ video: Video?) {
        if let shareLink = urlLink {
            let shareText = "Shared using Acorn"
            let shareUrl = URL(string: shareLink)
            let shareItems = [shareText, shareUrl ?? ""] as [Any]
            
            Analytics.logEvent(AnalyticsEventShare, parameters: [
                AnalyticsParameterItemID: video?.objectID ?? "",
                AnalyticsParameterItemCategory: video?.mainTheme ?? "",
                "item_source": video?.source ?? "",
                AnalyticsParameterContentType: video?.type ?? ""
                ])
            
            let activityController = UIActivityViewController(activityItems: shareItems,  applicationActivities: nil)
            DispatchQueue.main.async {
                self.present(activityController, animated: true)
            }
        }
    }
    
    func openOptions(anchor: UIView, video: Video) {
        let options = ["Not interested in videos", "Don't show from \(video.source ?? "")"]
        let dropdown = DropDown()
        dropdown.anchorView = anchor
        dropdown.dataSource = options
        dropdown.width = 300
        dropdown.direction = .bottom
        dropdown.backgroundColor = nightModeOn ? ResourcesNight.CARD_BG_COLOR : ResourcesDay.CARD_BG_COLOR
        dropdown.textColor = nightModeOn ? ResourcesNight.CARD_TEXT_COLOR : ResourcesDay.CARD_TEXT_COLOR
        dropdown.bottomOffset = CGPoint(x: 0, y: (dropdown.anchorView?.plainView.bounds.height)!)
        dropdown.selectionAction = { (index: Int, item: String) in
            if item == options[0] {
                self.defaults.set(false, forKey: "videosInFeedPref")
                self.dataSource.setVideosInFeedPreference(false)
            } else if item == options[1] {
                if let source = video.source {
                    var channelsRemoved = self.defaults.array(forKey: "videosInFeedChannelsToRemove") as? [String] ?? [String]()
                    channelsRemoved.append(source)
                    self.defaults.set(channelsRemoved, forKey: "videosInFeedChannelsToRemove")
                    self.dataSource.setVideosInFeedPreference(for: source, false)
                }
            }
        }
        dropdown.show()
        
        defaults.set(true, forKey: "hasSeenVideoOptions")
    }
    
    func upvoteActionTapped(video: Video, upvoteButton: UIButton, downvoteButton: UIButton) {
        if !isUserEmailVerified() {
            showEmailVerificationAlert(user: self.user!)
            return
        }
        
        upvoteButton.isEnabled = false
        downvoteButton.isEnabled = false
        
        var wasUpvoted = false
        var wasDownvoted = false
        
        if let upvoters = video.upvoters {
            if upvoters.keys.contains(self.uid!) {
                wasUpvoted = true
            }
        }
        
        if let downvoters = video.downvoters {
            if downvoters.keys.contains(self.uid!) {
                wasDownvoted = true
            }
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dataSource.updateVideoVote(video: video, actionIsUpvote: true, wasUpvoted: wasUpvoted, wasDownvoted: wasDownvoted) { dispatchGroup.leave() }
        
        dispatchGroup.enter()
        dataSource.updateUserVote(video: video, actionIsUpvote: true) { (userStatus) in
            if let userStatus = userStatus {
                let toastMessage = "Congratulations! You have grown into a \(userStatus)"
                self.view.makeToast(toastMessage, point: self.toastPosition, title: nil, image: nil, completion: nil)
            }
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            
            upvoteButton.isEnabled = true
            downvoteButton.isEnabled = true
        }
    }
    
    func downvoteActionTapped(video: Video, upvoteButton: UIButton, downvoteButton: UIButton) {
        if !isUserEmailVerified() {
            showEmailVerificationAlert(user: self.user!)
            return
        }
        
        upvoteButton.isEnabled = false
        downvoteButton.isEnabled = false
        
        var wasUpvoted = false
        var wasDownvoted = false
        
        if let upvoters = video.upvoters {
            if upvoters.keys.contains(self.uid!) {
                wasUpvoted = true
            }
        }
        
        if let downvoters = video.downvoters {
            if downvoters.keys.contains(self.uid!) {
                wasDownvoted = true
            }
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dataSource.updateVideoVote(video: video, actionIsUpvote: false, wasUpvoted: wasUpvoted, wasDownvoted: wasDownvoted) { dispatchGroup.leave() }
        
        dispatchGroup.enter()
        dataSource.updateUserVote(video: video, actionIsUpvote: false) { (userStatus) in
            if let userStatus = userStatus {
                let toastMessage = "Congratulations! You have grown into a \(userStatus)"
                self.view.makeToast(toastMessage, point: self.toastPosition, title: nil, image: nil, completion: nil)
            }
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            
            upvoteButton.isEnabled = true
            downvoteButton.isEnabled = true
        }
    }
    
    func saveActionTapped(video: Video, saveButton: UIButton) {
        //        saveButton.isEnabled = false
        //
        //        let dispatchGroup = DispatchGroup()
        //        dispatchGroup.enter()
        //        dataSource.updateVideoSave(video: video) { dispatchGroup.leave() }
        //
        //        dispatchGroup.enter()
        //        dataSource.updateUserSave(video: video) { dispatchGroup.leave() }
        //        dispatchGroup.notify(queue: .main) {
        //
        //            saveButton.isEnabled = true
        //        }
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
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
    
    func showAlert(title: String?, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(ac, animated: true, completion: nil)
    }
    
    func isUserEmailVerified() -> (Bool) {
        let globals = Globals.instance
        return globals.isUserEmailVerified
    }
    
    func hasOpenedArticle() -> (Bool) {
        let globals = Globals.instance
        return globals.hasOpenedArticle
    }
}

extension FeedViewController: MDCBottomNavigationBarDelegate {
    func bottomNavigationBar(_ bottomNavigationBar: MDCBottomNavigationBar, didSelect item: UITabBarItem) {
        print("item: \(item.tag)")
        if item.tag == 0 {
            self.getSubscriptionsFeed()
        } else if item.tag == 1 {
            self.getTrendingFeed()
        } else if item.tag == 2 {
            self.getDealsFeed()
        } else if item.tag == 3 {
            self.getSavedFeed()
        } else if item.tag == 4 {
            if isUserPremium {
                self.getNearbyFeed()
            } else {
                let toastMessage = "Refer a friend using the Share App Invite feature to access this premium feature!"
                self.view.makeToast(toastMessage, point: self.toastPosition, title: nil, image: nil, completion: nil)
            }
        } else if item.tag == 5 {
            self.getVideoFeed()
        }
    }
}

extension FeedViewController: CreatePostDelegate {
    func postCreated() {
        dismiss(animated: true, completion: { self.view.makeToast("Post Created!", point: self.toastPosition, title: nil, image: nil, completion: nil) })
    }
}

extension FeedViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Failed to monitor \(region!.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("received location update")
        guard let location = manager.location else {
            return
        }
        
        self.getNearestLocales(from: location, limit: 6) { (locales) in
            for station in locales {
                if let location = station.value["location"] as? CLLocation {
                    let region = CLCircularRegion(center: location.coordinate, radius: 1000, identifier: station.key)
                    region.notifyOnEntry = true
                    region.notifyOnExit = true
                    self.locationManager.startMonitoring(for: region)
                    print("monitoring \(station.key)")
                }
            }
        }
        
        self.getNearestSavedAddresses(from: location, limit: 6) { addresses in
            for address in addresses {
                if let addressLoc = address.value["location"] as? CLLocation {
                    let region = CLCircularRegion(center: addressLoc.coordinate, radius: 1000, identifier: "article_\(address.key)")
                    region.notifyOnEntry = true
                    region.notifyOnExit = true
                    self.locationManager.startMonitoring(for: region)
                    print("monitoring \(address.key)")
                }
            }
        }
        
        locationManager.stopUpdatingLocation()
    }
}

extension FeedViewController: FBNativeAdDelegate, FBNativeAdsManagerDelegate, FBAdViewDelegate {
    func nativeAdsFailedToLoadWithError(_ error: Error) {
        print("adLoader failed with error: \(error.localizedDescription)")
    }
    
    func nativeAdsLoaded() {
        print("nativeAdsLoaded")
        addNativeAdsToFeed()
        self.collectionView?.reloadData()
    }
    
    func loadAds() {
        adLoader = FBNativeAdsManager(placementID: self.nativeAdPlacementId, forNumAdsRequested: 10)
        if let adLoader = adLoader {
            print("loadAds")
            adLoader.delegate = self
            adLoader.loadAds()
        }
    }
    
    func addNativeAdsToFeed() {
        var index = 3
        let interval = 10
        if let adLoader = adLoader {
            for _ in 0..<adLoader.uniqueNativeAdCount {
                if index < articleList.count {
                    articleList.insert(adLoader.nextNativeAd!, at: index)
                    articleListIds.insert("ad", at: index)
                    index += interval
                } else {
                    break
                }
            }
        }
    }
}
