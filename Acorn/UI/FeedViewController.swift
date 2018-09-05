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

class FeedViewController: MDCCollectionViewController, FeedCvCellDelegate {
    
    @IBOutlet weak var moreOptionsButton: UIBarButtonItem!
    
    lazy var uid = Auth.auth().currentUser!.uid
    lazy var appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var floatingButtonOffset: CGFloat = 0.0
    var spinner: UIView?
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    let dataSource = DataSource.instance
    let loadTrigger: Int = 5
    
    var selectedFeed: String?
    var isNewLoad: Bool = false
    var isFirstTimeLogin: Bool = false
    
    let defaults = UserDefaults.standard
    var themeKey: String?
    var themeFilters: [String]?
    
    var articleList = [Article]()
    
    let bottomBarView = MDCBottomAppBarView()
    let subscriptionsButton = { () -> UIBarButtonItem in
        let button = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_checklist"), style: .plain, target: self, action: #selector(getSubscriptionsFeed))
        button.accessibilityLabel = "Subscriptions"
        button.tintColor = Resources.COLOR_ACCENT
        return button
    }()
    let recentButton = { () -> UIBarButtonItem in
        let button = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_history"), style: .plain, target: self, action: #selector(getRecentFeed))
        button.accessibilityLabel = "Recent"
        button.tintColor = UIColor.lightGray
        return button
    }()
    let trendingButton = { () -> UIBarButtonItem in
        let button = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_trending_up"), style: .plain, target: self, action: #selector(getTrendingFeed))
        button.accessibilityLabel = "Trending"
        button.tintColor = UIColor.lightGray
        return button
    }()
    let savedButton = { () -> UIBarButtonItem in
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
        bottomBarView.floatingButton.addTarget(self,
                                               action: #selector(didTapFloatingButton),
                                               for: .touchUpInside)
        
        // Set the image on the floating button.
        bottomBarView.floatingButton.setImage(#imageLiteral(resourceName: "ic_plus"), for: .normal)
        bottomBarView.floatingButton.setImage(#imageLiteral(resourceName: "ic_plus"), for: .highlighted)
        bottomBarView.floatingButton.setImageTintColor(.white, for: .normal)
        bottomBarView.floatingButton.setImageTintColor(.white, for: .highlighted)
        bottomBarView.floatingButton.accessibilityLabel = "Create post"
        
        // Set the position of the floating button.
        bottomBarView.floatingButtonPosition = .trailing
        
        // Theme the floating button.
        let colorScheme = MDCBasicColorScheme(primaryColor: Resources.COLOR_ACCENT)
        MDCButtonColorThemer.apply(colorScheme, to: bottomBarView.floatingButton)
        
        // Configure the navigation buttons to be shown on the bottom app bar.
        
        navigationController?.setToolbarHidden(true, animated: false)
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = Resources.COLOR_PRIMARY
        
        bottomBarView.leadingBarButtonItems = [ subscriptionsButton, recentButton, trendingButton, savedButton ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        guard let collectionView = collectionView else {
            return
        }
        
        isNewLoad = true
        
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
    }
    
    @objc private func refreshOptions(sender: UIRefreshControl) {
        reloadFeed()
        sender.endRefreshing()
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
//        collectionView?.frame = CGRect(x: 0, y: 0, width: (collectionView?.bounds.width)!, height: (collectionView?.bounds.height)! - size.height)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let currentUser = Auth.auth().currentUser  {
            checkEmailVerified(user: currentUser)
            self.uid = currentUser.uid
            dataSource.getThemeSubscriptions(user: currentUser)
            themeKey = defaults.string(forKey: "themeKey")
            themeFilters = defaults.stringArray(forKey: "themeFilters")
            //            Crashlytics.sharedInstance().setUserIdentifier(currentUser.uid)
        } else {
            launchLogin()
            return
        }
        
        // If user has no theme prefs, go to theme selection scene
        print("themeKey: \(themeKey ?? "nil")")
        if themeKey == nil {
            isFirstTimeLogin = true
            performSegue(withIdentifier: "Edit Subscriptions", sender: self)
        }
        
        MDCSnackbarManager.setBottomOffset(bottomBarView.frame.height)
        navigationItem.leftBarButtonItems?[0].accessibilityLabel = "Notifications"
        navigationItem.rightBarButtonItems?[0].accessibilityLabel = "More options"
        navigationItem.rightBarButtonItems?[1].accessibilityLabel = "Search articles"
        
        if isNewLoad {
            loadData()
            isNewLoad = false
        }
    }
    
    private func launchLogin() {
        let authViewController = FUIAuth.defaultAuthUI()?.authViewController()
        authViewController?.navigationBar.isHidden = true
        self.present(authViewController!, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataSource.removeFeedObservers()
        MDCSnackbarManager.setBottomOffset(0)
        if let spinner = spinner {
            removeSpinner(spinner)
        }
    }
    
    @objc private func getSubscriptionsFeed() {
        print("subscriptions")
        if selectedFeed != "Subscriptions" {
            resetView()
            selectedFeed = "Subscriptions"
            dataSource.getSubscriptionsFeed() { (articles: [Article]) -> () in
                self.articleList = articles
                print("articleList count: \(self.articleList.count)")
                self.subscriptionsButton.tintColor = Resources.COLOR_ACCENT
                self.collectionView?.reloadData()
                self.collectionViewLayout.invalidateLayout()
                if let spinner = self.spinner { self.removeSpinner(spinner) }
            }
        }
    }
    
    private func getMoreSubscriptionsFeed(startAt: Double) {
        if selectedFeed != "Subscriptions" { return }
        let initialList = self.articleList
        
        print("additional subscriptions")
        dataSource.getSubscriptionsFeed(startAt: startAt) { (articles: [Article]) -> () in
            var combinedList = Array(initialList.dropLast())
            combinedList.append(contentsOf: articles)
            self.articleList = combinedList
            print("articleList count: \(self.articleList.count)")
            self.collectionView?.reloadData()
            self.collectionViewLayout.invalidateLayout()
            if let spinner = self.spinner { self.removeSpinner(spinner) }
        }
    }
    
    @objc private func getRecentFeed() {
        print("recent")
        if selectedFeed != "Recent" {
            resetView()
            selectedFeed = "Recent"
            dataSource.getRecentFeed() { (articles: [Article]) -> () in
                self.articleList = articles
                print("articleList count: \(self.articleList.count)")
                self.recentButton.tintColor = Resources.COLOR_ACCENT
                self.collectionView?.reloadData()
                self.collectionViewLayout.invalidateLayout()
                if let spinner = self.spinner { self.removeSpinner(spinner) }
            }
        }
    }
    
    private func getMoreRecentFeed(startAt: Double) {
        if selectedFeed != "Recent" { return }
        let initialList = self.articleList
        
        print("additional recent")
        dataSource.getRecentFeed(startAt: startAt) { (articles: [Article]) -> () in
            var combinedList = Array(initialList.dropLast())
            combinedList.append(contentsOf: articles)
            self.articleList = combinedList
            print("articleList count: \(self.articleList.count)")
            self.collectionView?.reloadData()
            self.collectionViewLayout.invalidateLayout()
            if let spinner = self.spinner { self.removeSpinner(spinner) }
        }
    }
    
    @objc private func getTrendingFeed() {
        print("trending")
        if selectedFeed != "Trending" {
            resetView()
            selectedFeed = "Trending"
            dataSource.getTrendingFeed() { (articles: [Article]) -> () in
                self.articleList = articles
                print("articleList count: \(self.articleList.count)")
                self.trendingButton.tintColor = Resources.COLOR_ACCENT
                self.collectionView?.reloadData()
                self.collectionViewLayout.invalidateLayout()
                if let spinner = self.spinner { self.removeSpinner(spinner) }
            }
        }
    }
    
    private func getMoreTrendingFeed(startAt: String) {
        if selectedFeed != "Trending" { return }
        let initialList = self.articleList
        
        print("additional trending")
        dataSource.getTrendingFeed(startAt: startAt) { (articles: [Article]) -> () in
            var combinedList = Array(initialList.dropLast())
            combinedList.append(contentsOf: articles)
            self.articleList = combinedList
            print("articleList count: \(self.articleList.count)")
            self.collectionView?.reloadData()
            self.collectionViewLayout.invalidateLayout()
            if let spinner = self.spinner { self.removeSpinner(spinner) }
        }
    }
    
    @objc private func getSavedFeed() {
        print("saved")
        if selectedFeed != "Saved" {
            resetView()
            selectedFeed = "Saved"
            dataSource.getSavedFeed(startAt: 0) { (articles: [Article]) -> () in
                self.articleList = articles
                print("articleList count: \(self.articleList.count)")
                self.savedButton.tintColor = Resources.COLOR_ACCENT
                self.collectionView?.reloadData()
                self.collectionViewLayout.invalidateLayout()
                if let spinner = self.spinner { self.removeSpinner(spinner) }
            }
        }
    }
    
    private func getMoreSavedFeed(startAt: Int) {
        if selectedFeed != "Saved" { return }
        let initialList = self.articleList
        
        print("additional saved")
        dataSource.getSavedFeed(startAt: startAt) { (articles: [Article]) -> () in
            var combinedList = Array(initialList.dropLast())
            combinedList.append(contentsOf: articles)
            self.articleList = combinedList
            print("articleList count: \(self.articleList.count)")
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
        }
    }
    
    @objc private func didTapFloatingButton() {
        print("create post")
        performSegue(withIdentifier: "Create Post", sender: self)
    }
    
    @IBAction func didTapSearch(_ sender: Any) {
        performSegue(withIdentifier: "Search", sender: self)
    }
    
   
    @IBAction func didTapMoreOptions(_ sender: Any) {
        let dropdown = DropDown()
        dropdown.anchorView = moreOptionsButton
        dropdown.dataSource = Resources.OPTIONS_LIST_FEED
        dropdown.width = 200
        dropdown.direction = .bottom
        dropdown.backgroundColor = Resources.OPTIONS_BG_COLOR
        dropdown.textColor = Resources.OPTIONS_TEXT_COLOR
        dropdown.bottomOffset = CGPoint(x: 0, y: (dropdown.anchorView?.plainView.bounds.height)!)
        dropdown.selectionAction = { (index: Int, item: String) in
            if item == "Edit Subscriptions" {
                self.performSegue(withIdentifier: Resources.OPTIONS_LIST_FEED[index], sender: self)
            } else if item == "Settings" {
                self.view.makeToast("This feature will be implemented soon!")
            } else if item == "Log Out" {
                let ac = UIAlertController(title: nil, message: "Would you like to log out?", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                ac.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
                    do {
                        try Auth.auth().signOut()
                    } catch {
                        print("Error signing out: \(error.localizedDescription)")
                    }
                    self.resetView()
                    self.selectedFeed = nil
                    self.launchLogin()
                }))
                self.present(ac, animated: true, completion: nil)
            }
        }
        dropdown.show()
    }
    
    @IBAction func didTapNotifications(_ sender: Any) {
        self.view.makeToast("This feature will be implemented soon!")
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
            
            cell.populateCell(article: article)
            
            return cell
        }
        
        if article.type == "article" {
            if (article.imageUrl != nil && article.imageUrl != "") {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCell", for: indexPath) as! FeedCvCell
                cell.delegate = self
                cell.article = article
                
                cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellNoImage", for: indexPath) as! FeedCvCellNoImage
                cell.delegate = self
                cell.article = article
                
                cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                return cell
            }
        } else {
            if (article.link != nil && article.link != "") {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellPostWithArticle", for: indexPath) as! FeedCvCellPostWithArticle
                cell.delegate = self
                cell.article = article
                
                cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                return cell
            } else {
                if (article.postImageUrl != nil && article.postImageUrl != "") {
                    if (article.title != nil && article.title != "") {
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellPostWithArticle", for: indexPath) as! FeedCvCellPostWithArticle
                        cell.delegate = self
                        cell.article = article
                        
                        cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                        return cell
                    } else {
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellPost", for: indexPath) as! FeedCvCellPost
                        cell.delegate = self
                        cell.article = article
                        
                        cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                        return cell
                    }
                } else {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCvCellPostNoImage", for: indexPath) as! FeedCvCellPostNoImage
                    cell.delegate = self
                    cell.article = article
                    
                    cell.populateContent(article: article, selectedFeed: self.selectedFeed!)
                    return cell
                }
            }
        }
    }
    
    func openArticle(_ cell: FeedCvCell) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "WebView") as? WebViewViewController
        vc?.article = cell.article
        vc?.feedVC = self
        present(vc!, animated: true, completion: nil)
    }
    
    func openArticle(_ cell: FeedCvCellNoImage) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "WebView") as? WebViewViewController
        vc?.article = cell.article
        vc?.feedVC = self
        present(vc!, animated: true, completion: nil)
    }
    
    func openArticle(_ cell: FeedCvCellPostWithArticle) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "WebView") as? WebViewViewController
        vc?.article = cell.article
        vc?.feedVC = self
        present(vc!, animated: true, completion: nil)
    }
    
    func openArticle(_ cell: FeedCvCellSaved) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "WebView") as? WebViewViewController
        vc?.article = cell.article
        vc?.feedVC = self
        present(vc!, animated: true, completion: nil)
    }
    
    func openComments(_ cell: FeedCvCell) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Comment") as? CommentViewController
        vc?.article = cell.article
        present(vc!, animated:true, completion: nil)
    }
    
    func openComments(_ cell: FeedCvCellNoImage) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Comment") as? CommentViewController
        vc?.article = cell.article
        present(vc!, animated:true, completion: nil)
    }
    
    func openComments(_ cell: FeedCvCellPost) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Comment") as? CommentViewController
        vc?.article = cell.article
        present(vc!, animated:true, completion: nil)
    }
    
    func openComments(_ cell: FeedCvCellPostNoImage) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Comment") as? CommentViewController
        vc?.article = cell.article
        present(vc!, animated:true, completion: nil)
    }
    
    func openComments(_ cell: FeedCvCellPostWithArticle) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Comment") as? CommentViewController
        vc?.article = cell.article
        present(vc!, animated:true, completion: nil)
    }
    
    func openComments(_ cell: FeedCvCellSaved) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Comment") as? CommentViewController
        vc?.article = cell.article
        present(vc!, animated:true, completion: nil)
    }
    
    func openShareActivity(_ cell: FeedCvCell) {
        if let shareLink = cell.article?.link {
            print(shareLink)
            let activityController = UIActivityViewController(activityItems: [URL(string: shareLink) ?? ""],  applicationActivities: nil)
            DispatchQueue.main.async {
                self.present(activityController, animated: true)
            }
        }
    }
    
    func openShareActivity(_ cell: FeedCvCellNoImage) {
        if let shareLink = cell.article?.link {
            let activityController = UIActivityViewController(activityItems: [URL(string: shareLink) ?? ""],  applicationActivities: nil)
            DispatchQueue.main.async {
                self.present(activityController, animated: true)
            }
        }
    }
    
    func openShareActivity(_ cell: FeedCvCellPostWithArticle) {
        if let shareLink = cell.article?.link {
            let activityController = UIActivityViewController(activityItems: [URL(string: shareLink) ?? ""],  applicationActivities: nil)
            DispatchQueue.main.async {
                self.present(activityController, animated: true)
            }
        }
    }
    
    func openImage(_ cell: FeedCvCellPost) {
        if let link = cell.article?.link {
            let image = LightboxImage(imageURL: URL(string: link)!)
            let lightbox = LightboxController(images: [image])
            lightbox.dynamicBackground = true
            present(lightbox, animated: true, completion: nil)
        }
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
            let article = articleList.last
            switch selectedFeed {
            case "Subscriptions":
                getMoreSubscriptionsFeed(startAt: (article?.pubDate)!)
            case "Recent":
                getMoreRecentFeed(startAt: (article?.pubDate)!)
            case "Trending":
                getMoreTrendingFeed(startAt: (article?.trendingIndex)!)
            case "Saved":
                getMoreSavedFeed(startAt: articleList.count)
            default:
                print("selection not valid")
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
    
    func checkEmailVerified(user: User) {
        user.reload()
        if !user.isEmailVerified {
            let ac = UIAlertController(title: nil, message: "Please verify your email address.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            ac.addAction(UIAlertAction(title: "Re-send verification email", style: .destructive, handler: { _ in
                user.sendEmailVerification()
            }))
            self.present(ac, animated: true, completion: nil)
        }
    }
}

extension FeedViewController: CreatePostDelegate {
    func postCreated() {
        dismiss(animated: true, completion: { self.view.makeToast("Post created!") })
    }
}

