//
//  WebViewViewController.swift
//  Acorn
//
//  Created by macOS on 15/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import WebKit
import FirebaseUI
import Firebase
import DropDown
import Toast_Swift

class WebViewViewController: UIViewController, WKUIDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var searchStackView: UIStackView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var messageOverlayView: UIView!
    @IBOutlet weak var messageOverlayLabel: UILabel!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    @IBOutlet weak var moreOptionsButton: UIBarButtonItem!
    @IBOutlet weak var actionButtonStackView: UIStackView!
    @IBOutlet weak var upvoteButton: BounceButton!
    @IBOutlet weak var downvoteButton: BounceButton!
    @IBOutlet weak var commentButton: BounceButton!
    @IBOutlet weak var saveButton: BounceButton!
    @IBOutlet weak var shareButton: BounceButton!
    
    
    var articleId: String?
    var postcode: [String]?
    var article: Article?
    var isFollowedByUser: Bool = false
    
    var htmlString = ""
    var baseUrl = ""
    var didFinishInitialLoad = false
    
    var feedVC: FeedViewController?
    var searchVC: SearchViewController?
    
    lazy var user = Auth.auth().currentUser!
    lazy var uid = user.uid
    
    let dataSource = DataSource.instance
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    var nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    var defaultTint: UIColor?
    var upvoteTint: UIColor?
    var downvoteTint: UIColor?
    var commentTint: UIColor?
    var saveTint: UIColor?
    var shareTint: UIColor?
    
    var searchIndex = 0
    var resultCount = 0
    var postcodeIndex = 0
    
    let timeLog = TimeLog()
    var appearTime: Double = 0
    var activeTime: Double = 0
    var readTime: Int = 0
    
    lazy var toastPosition = CGPoint(x: self.view.bounds.size.width / 2.0, y: (self.view.bounds.size.height - 30) - 20 - actionButtonStackView.frame.height)
    
    // Ad
    let bannerView = { () -> GADBannerView in
        let bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.adUnitID = "ca-app-pub-9396779536944241/8919524667"
        return bannerView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stackView.insertArrangedSubview(bannerView, at: 4)
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: bannerView.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: bannerView.rightAnchor)
        ])
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        if hasOpenedArticle() {
            messageOverlayView.isHidden = true
        } else {
            messageOverlayView.sizeToFit()
            messageOverlayView.layoutIfNeeded()
            messageOverlayView.layer.masksToBounds = false
            messageOverlayView.layer.cornerRadius = 15
            messageOverlayView.layer.shadowColor = UIColor.black.cgColor
            messageOverlayView.layer.shadowOpacity = 0.5
            messageOverlayView.layer.shadowOffset = .zero
            messageOverlayView.layer.shadowRadius = 5
            messageOverlayView.layer.shadowPath = UIBezierPath(roundedRect: messageOverlayView.bounds, cornerRadius: 15).cgPath
            
            let globals = Globals.instance
            globals.hasOpenedArticle = true
        }
            
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: URL(string: "about:blank")!))
        
        searchBar.delegate = self
        searchStackView.isHidden = true
        
        let backSwipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(didSwipeBack(_:)))
        backSwipeGesture.edges = .left
        backSwipeGesture.delegate = self
        mainView.addGestureRecognizer(backSwipeGesture)
        
        if nightModeOn {
            enableNightMode()
        } else {
            disableNightMode()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeEnabled), name: .nightModeOn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeDisabled), name: .nightModeOff, object: nil)
        
        timeLog.userId = uid
        timeLog.itemId = articleId
        timeLog.type = "article"
        timeLog.openTime = Date().timeIntervalSince1970 * 1000
    }
    
    @objc func didSwipeBack(_ sender: UIScreenEdgePanGestureRecognizer) {
        let dX = sender.translation(in: mainView).x
        if sender.state == .ended {
            let fraction = abs(dX/mainView.bounds.width)
            if fraction > 0.3 {
                if !webView.canGoBack {
                    dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        decisionHandler(.allow)
    }
    
    @objc func nightModeEnabled() {
        enableNightMode()
    }
    
    @objc func nightModeDisabled() {
        disableNightMode()
    }
    
    func enableNightMode() {
        nightModeOn = true
        self.mainView.backgroundColor = ResourcesNight.COLOR_BG_MAIN
        webView.backgroundColor = ResourcesNight.COLOR_BG_MAIN
        actionButtonStackView.backgroundColor = ResourcesNight.COLOR_BG
        messageOverlayView.backgroundColor = ResourcesNight.CARD_BG_COLOR
        messageOverlayLabel.textColor = ResourcesNight.CARD_TEXT_COLOR
        
        defaultTint = ResourcesNight.BUTTON_DEFAULT_TINT_COLOR
        upvoteTint = ResourcesNight.UPVOTE_TINT_COLOR
        downvoteTint = ResourcesNight.DOWNVOTE_TINT_COLOR
        commentTint = ResourcesNight.COMMENT_TINT_COLOR
        saveTint = ResourcesNight.SAVE_TINT_COLOR
        shareTint = ResourcesNight.SHARE_TINT_COLOR
    }
    
    func disableNightMode() {
        nightModeOn = false
        self.mainView.backgroundColor = ResourcesDay.COLOR_BG_MAIN
        webView.backgroundColor = ResourcesDay.COLOR_BG_MAIN
        actionButtonStackView.backgroundColor = ResourcesDay.COLOR_BG
        messageOverlayView.backgroundColor = ResourcesDay.COLOR_BG
        messageOverlayLabel.textColor = ResourcesDay.CARD_TEXT_COLOR
        
        defaultTint = ResourcesDay.BUTTON_DEFAULT_TINT_COLOR
        upvoteTint = ResourcesDay.UPVOTE_TINT_COLOR
        downvoteTint = ResourcesDay.DOWNVOTE_TINT_COLOR
        commentTint = ResourcesDay.COMMENT_TINT_COLOR
        saveTint = ResourcesDay.SAVE_TINT_COLOR
        shareTint = ResourcesDay.SHARE_TINT_COLOR
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("webview: viewDidAppear")
        super.viewDidAppear(true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            UIView.animate(withDuration: 1.5, animations: {
                self.messageOverlayView.alpha = 0.0
            })
        }
        
        let localDb = LocalDb.instance
        localDb.openDatabase()
        if let localArticle = localDb.getArticle(articleId!) {
            let baseUrlPattern = try? NSRegularExpression(pattern:"(https?://.*?/).*", options: .caseInsensitive)
            baseUrl = baseUrlPattern?.stringByReplacingMatches(in: (localArticle.link)!, options: [], range: NSMakeRange(0, (localArticle.link)!.count), withTemplate: "$1") ?? ""
            if ((localArticle.htmlContent) != nil) {
                loadFromLocalDb(localArticle)
            } else {
                loadFromFirebaseDb()
            }
        } else {
            loadFromFirebaseDb()
        }
        
        appearTime = Date().timeIntervalSince1970 * 1000
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            self.progressView.isHidden = self.webView.estimatedProgress == 1
            self.progressView.progress = Float(self.webView.estimatedProgress)
        }
    }
    
    func loadFromLocalDb(_ localArticle: dbArticle) {
        print("loaded from localDb")
        htmlString = HtmlUtils().generateHtmlContent(localArticle.title ?? "", localArticle.link, localArticle.htmlContent ?? "", localArticle.author, localArticle.source, DateUtils.parsePrettyDate(unixTimestamp: -(localArticle.pubDate)!))
        //            print(htmlString.prefix(20))
        self.webView.loadHTMLString(htmlString, baseURL: URL(string: baseUrl))
        
        self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        let wordCount = htmlString.split(separator: " ").count
        self.readTime = Int(ceil(Double(wordCount) / 200.0))
        dataSource.setArticleReadTime(articleId: self.articleId!, readTime: self.readTime)
        
        dataSource.observeSingleArticle(articleId: articleId!) { (retrievedArticle) in
            self.article = retrievedArticle
            
            if let tokens = self.article?.notificationTokens {
                self.isFollowedByUser = tokens.keys.contains(self.uid)
            } else {
                self.isFollowedByUser = false
            }
            
            if let upvoters = self.article?.upvoters {
                if upvoters.keys.contains(self.uid) {
                    self.upvoteButton.tintColor = self.upvoteTint
                }
            }
            
            if let downvoters = self.article?.downvoters {
                if downvoters.keys.contains(self.uid) {
                    self.downvoteButton.tintColor = self.downvoteTint
                }
            }
            
            if let commenters = self.article?.commenters {
                if commenters.keys.contains(self.uid) {
                    self.commentButton.tintColor = self.commentTint
                }
            }
            
            if let savers = self.article?.savers {
                if savers.keys.contains(self.uid) {
                    self.saveButton.tintColor = self.saveTint
                }
            }
            
            if let sharers = self.article?.sharers {
                if sharers.keys.contains(self.uid) {
                    self.shareButton.tintColor = self.shareTint
                }
            }
            
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterItemID: self.article?.objectID ?? "",
                AnalyticsParameterItemCategory: self.article?.mainTheme ?? "",
                "item_source": self.article?.source ?? "",
                AnalyticsParameterContentType: self.article?.type ?? ""
                ])
        }
    }
        
    func loadFromFirebaseDb() {
        dataSource.observeSingleArticle(articleId: articleId!) { (retrievedArticle) in
            self.article = retrievedArticle
            print("loaded from firebaseDb")
            
            if (self.article?.type)! == "article" {
                self.genHtml(for: self.article!)
            } else {
                let link = URL(string: (self.article?.link)!)
                let request = URLRequest(url: link!)
                self.webView.load(request)
            }
            
            self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
            
            if let tokens = self.article?.notificationTokens {
                self.isFollowedByUser = tokens.keys.contains(self.uid)
            } else {
                self.isFollowedByUser = false
            }
            
            if let upvoters = self.article?.upvoters {
                if upvoters.keys.contains(self.uid) {
                    self.upvoteButton.tintColor = self.upvoteTint
                }
            }
            
            if let downvoters = self.article?.downvoters {
                if downvoters.keys.contains(self.uid) {
                    self.downvoteButton.tintColor = self.downvoteTint
                }
            }
            
            if let commenters = self.article?.commenters {
                if commenters.keys.contains(self.uid) {
                    self.commentButton.tintColor = self.commentTint
                }
            }
            
            if let savers = self.article?.savers {
                if savers.keys.contains(self.uid) {
                    self.saveButton.tintColor = self.saveTint
                }
            }
            
            if let sharers = self.article?.sharers {
                if sharers.keys.contains(self.uid) {
                    self.shareButton.tintColor = self.shareTint
                }
            }
            
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterItemID: self.article?.objectID ?? "",
                AnalyticsParameterItemCategory: self.article?.mainTheme ?? "",
                "item_source": self.article?.source ?? "",
                AnalyticsParameterContentType: self.article?.type ?? ""
                ])
        }
    }
    
    func genHtml(for article: Article?) {
        let htmlUtils = HtmlUtils()
        let baseUrlPattern = try? NSRegularExpression(pattern:"(https?://.*?/).*", options: .caseInsensitive)
        baseUrl = baseUrlPattern?.stringByReplacingMatches(in: (article?.link)!, options: [], range: NSMakeRange(0, (article?.link)!.count), withTemplate: "$1") ?? ""
        let generatedHtml = htmlUtils.regenArticleHtml((article?.link)!, (article?.title)!, (article?.author)!, (article?.source)!, DateUtils.parsePrettyDate(unixTimestamp: -((article?.pubDate)!)), article?.selector, (article?.objectID)!)
        
        let isSuccessful = generatedHtml != nil && !(generatedHtml?.isEmpty)!
        
        if isSuccessful {
            if article?.readTime == nil {
                let wordCount = generatedHtml?.split(separator: " ").count
                self.readTime = Int(ceil(Double(wordCount!) / 200.0))
                dataSource.setArticleReadTime(article: self.article!, readTime: self.readTime)
            }
            
            htmlString = generatedHtml!
            webView.loadHTMLString(htmlString, baseURL: URL(string: baseUrl))
        } else {
            if let link = URL(string: (article?.link)!) {
                let request = URLRequest(url: link)
                self.webView.load(request)
                return
            }
            
            dismiss(animated: true, completion: nil)
            if let vc = feedVC {
                vc.view.makeToast("Failed to load article", point: toastPosition, title: nil, image: nil, completion: nil)
            } else if let vc = searchVC {
                vc.view.makeToast("Failed to load article", point: toastPosition, title: nil, image: nil, completion: nil)
            }
        }
    }

    @IBAction func didTapBack(_ sender: Any) {
        if webView.canGoBack {
            webView.goBack()
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func didTapSearchButton(_ sender: Any) {
        searchButtonTapped()
    }
    
    func searchButtonTapped() {
        UIView.animate(withDuration: 0.3) {
            self.searchStackView.isHidden = !self.searchStackView.isHidden
            self.nextButton.isHidden = true
        }
        if searchStackView.isHidden {
            searchBar.resignFirstResponder()
            webView.evaluateJavaScript("uiWebview_RemoveAllHighlights()") { (result, error) in
                if let error = error {
                    print(error)
                }
            }
        } else {
            searchBar.becomeFirstResponder()
        }
    }
    
    @IBAction func didTapNextButton(_ sender: Any) {
        nextButtonTapped()
    }
    
    func nextButtonTapped() {
        if let postcode = postcode {
            if postcodeIndex < postcode.count {
                let searchText = postcode[postcodeIndex]
                searchBar.text = searchText
                if searchIndex < 1 {
                    findPostcode(searchText) { self.nextPostcode() }
                    nextButton.setTitle("Next", for: .normal)
                } else {
                    nextPostcode()
                }
            } else {
                self.view.makeToast("No more nearby addresses", point: toastPosition, title: nil, image: nil, completion: nil)
                postcodeIndex = 0
                nextButton.setTitle("Find", for: .normal)
            }
        }
    }
    
    func findPostcode(_ postcode: String, onComplete: @escaping () -> ()) {
        let startSearch = "uiWebview_HighlightAllOccurrencesOfString('\(postcode)')"
        print("search: \(startSearch)")
        
        webView.evaluateJavaScript(startSearch) { (result, error) in
            if let error = error {
                print(error)
                return
            }
            
            self.webView.evaluateJavaScript("uiWebview_SearchResultCount") { (count, error) in
                if let error = error {
                    print(error)
                    return
                }
                
                self.resultCount = count as! Int
                self.searchIndex = self.resultCount
                onComplete()
            }
        }
    }
    
    func nextPostcode() {
        print("searchIndex: \(searchIndex), postcodeIndex: \(postcodeIndex)")
        let goToNext = "uiWebview_ScrollTo('\(self.searchIndex - 1)')"
        self.webView.evaluateJavaScript(goToNext) { (result, error) in
            if let error = error {
                print(error)
            }
        }
        self.searchIndex -= 1
        if self.searchIndex < 1 {
            self.postcodeIndex += 1
        }
    }
    
    @IBAction func didTapMoreOptionsButton(_ sender: Any) {
        let dropdown = DropDown()
        dropdown.anchorView = moreOptionsButton
        
        if isFollowedByUser {
            dropdown.dataSource = ["Unfollow article"]
        } else {
            dropdown.dataSource = ["Follow article"]
        }
        
        dropdown.width = 200
        dropdown.direction = .bottom
        dropdown.backgroundColor = nightModeOn ? ResourcesNight.OPTIONS_BG_COLOR : ResourcesDay.OPTIONS_BG_COLOR
        dropdown.textColor = nightModeOn ? ResourcesNight.OPTIONS_TEXT_COLOR : ResourcesDay.OPTIONS_TEXT_COLOR
        dropdown.bottomOffset = CGPoint(x: 0, y: (dropdown.anchorView?.plainView.bounds.height)!)
        dropdown.selectionAction = { (index: Int, item: String) in
            if item == "Follow article" {
                self.dataSource.follow(articleId: self.article!.objectID)
                self.isFollowedByUser = true
            } else if item == "Unfollow article" {
                self.dataSource.unfollow(articleId: self.article!.objectID)
                self.isFollowedByUser = false
            }
        }
        dropdown.show()
    }
    
    @IBAction func didTapUpvoteButton(_ sender: Any) {
        if !isUserEmailVerified() {
            showEmailVerificationAlert(user: user)
            return
        }
        
        upvoteButton.isEnabled = false
        downvoteButton.isEnabled = false
        
        let wasUpvoted = self.upvoteButton.tintColor == self.upvoteTint ? true : false
        let wasDownvoted = self.downvoteButton.tintColor == self.downvoteTint ? true : false
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dataSource.updateArticleVote(article: article!, actionIsUpvote: true, wasUpvoted: wasUpvoted, wasDownvoted: wasDownvoted) {
            self.upvoteButton.tintColor = wasUpvoted ? self.defaultTint : self.upvoteTint
            self.downvoteButton.tintColor = self.defaultTint
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        dataSource.updateUserVote(article: article!, actionIsUpvote: true) { (userStatus) in
            if let userStatus = userStatus {
                self.view.makeToast("Congratulations! You have grown into a \(userStatus)", point: self.toastPosition, title: nil, image: nil, completion: nil)
            }
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            
            self.upvoteButton.isEnabled = true
            self.downvoteButton.isEnabled = true
        }
    }
    
    @IBAction func didTapDownvoteButton(_ sender: Any) {
        if !isUserEmailVerified() {
            showEmailVerificationAlert(user: user)
            return
        }
        
        upvoteButton.isEnabled = false
        downvoteButton.isEnabled = false
        
        let wasUpvoted = self.upvoteButton.tintColor == self.upvoteTint ? true : false
        let wasDownvoted = self.downvoteButton.tintColor == self.downvoteTint ? true : false
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dataSource.updateArticleVote(article: article!, actionIsUpvote: false, wasUpvoted: wasUpvoted, wasDownvoted: wasDownvoted) {
            self.upvoteButton.tintColor = self.defaultTint
            self.downvoteButton.tintColor = wasDownvoted ? self.defaultTint : self.downvoteTint
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        dataSource.updateUserVote(article: article!, actionIsUpvote: false) { (userStatus) in
            if let userStatus = userStatus {
                self.view.makeToast("Congratulations! You have grown into a \(userStatus)", point: self.toastPosition, title: nil, image: nil, completion: nil)
            }
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            self.upvoteButton.isEnabled = true
            self.downvoteButton.isEnabled = true
        }
    }
    
    @IBAction func didTapCommentButton(_ sender: Any) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Comment") as? CommentViewController
        vc?.articleId = article?.objectID
        present(vc!, animated:true, completion: nil)
    }
    
    @IBAction func didTapSaveButton(_ sender: Any) {
        saveButton.isEnabled = false
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dataSource.updateArticleSave(article: article!) { dispatchGroup.leave() }
        
        dispatchGroup.enter()
        dataSource.updateUserSave(article: article!) { dispatchGroup.leave() }
        dispatchGroup.notify(queue: .main) {
            
            self.saveButton.isEnabled = true
        }
    }
    
    @IBAction func didTapShareButton(_ sender: Any) {
        guard let article = self.article else { return }
        let url = ShareUtils.createShareUri(articleId: article.objectID, url: article.link!, sharerId: uid)
        ShareUtils.createShortDynamicLink(url: url, sharerId: uid) { (dynamicLink) in
            let shareText = "Shared using Acorn"
            let shareUrl = URL(string: dynamicLink)
            let shareItems = [shareText, shareUrl ?? ""] as [Any]
            
            Analytics.logEvent(AnalyticsEventShare, parameters: [
                AnalyticsParameterItemID: self.article?.objectID ?? "",
                AnalyticsParameterItemCategory: self.article?.mainTheme ?? "",
                "item_source": self.article?.source ?? "",
                AnalyticsParameterContentType: self.article?.type ?? ""
            ])
            
            let activityController = UIActivityViewController(activityItems: shareItems,  applicationActivities: nil)
            DispatchQueue.main.async {
                self.present(activityController, animated: true)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("viewDidDisappear")
        let now = Date().timeIntervalSince1970 * 1000
        activeTime += now - appearTime
        timeLog.activeTime = activeTime
        timeLog.closeTime = now
        if (readTime > 0) { timeLog.percentReadTimeActive = activeTime / Double(readTime) }
        self.dataSource.logItemTimeLog(timeLog)
        super.viewDidDisappear(true)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension WebViewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if webView.url?.absoluteString == "about:blank" {
            if didFinishInitialLoad {
                webView.loadHTMLString(htmlString, baseURL: URL(string: baseUrl))
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.progressView.setProgress(0.0, animated: false)
        
        didFinishInitialLoad = true
        
        if let path = Bundle.main.path(forResource: "UIWebViewSearch", ofType: "js"), let jsString = try? String(contentsOfFile: path, encoding: .utf8) {
            self.webView.evaluateJavaScript(jsString) { (result, error) in
                if let error = error {
                    print(error)
                    return
                }
            }
        }
        
        if self.didFinishInitialLoad, let postcode = postcode {
            nextButton.setTitle("Find", for: .normal)
            searchStackView.isHidden = false
            nextButton.isHidden = false
            let searchText = postcode[postcodeIndex]
            searchBar.text = searchText
        }
    }
}

extension WebViewViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let startSearch = "uiWebview_HighlightAllOccurrencesOfString('\(searchText)')"
        
        webView.evaluateJavaScript(startSearch) { (result, error) in
            if let error = error {
                print(error)
                return
            }
            
            self.webView.evaluateJavaScript("uiWebview_SearchResultCount") { (count, error) in
                if let error = error {
                    print(error)
                    return
                }
                
                self.resultCount = count as! Int
                self.searchIndex = self.resultCount
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchIndex < 1 {
            self.view.makeToast("You've reached the end of the article!", point: toastPosition, title: nil, image: nil, completion: nil)
            searchIndex = resultCount
        } else {
            let goToNext = "uiWebview_ScrollTo('\(searchIndex - 1)')"
            webView.evaluateJavaScript(goToNext)
            searchIndex -= 1
        }
    }
}

extension WebViewViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y > scrollView.frame.height) {
            let scrollPercent = Double(scrollView.contentOffset.y / (scrollView.contentSize.height - scrollView.frame.height))
            print("scrollPercent: \(scrollPercent)")
            if scrollPercent > timeLog.percentScroll ?? 0 { timeLog.percentScroll = min(1.0, scrollPercent) }
        }
    }
}
