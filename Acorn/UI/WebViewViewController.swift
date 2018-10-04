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

class WebViewViewController: UIViewController, WKUIDelegate {

    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var searchBar: UISearchBar!
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
    var article: Article?
    var isFollowedByUser: Bool = false
    
    var feedVC: FeedViewController?
    var searchVC: SearchViewController?
    
    lazy var user = Auth.auth().currentUser!
    lazy var uid = user.uid
    
    let dataSource = DataSource.instance
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    var nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    var upvoteTint: UIColor?
    var downvoteTint: UIColor?
    var commentTint: UIColor?
    var saveTint: UIColor?
    var shareTint: UIColor?
    
    var spinner: UIView?
    
    var searchIndex = 0
    var resultCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        webView.navigationDelegate = self
        
        searchBar.isHidden = true
        
        if nightModeOn {
            enableNightMode()
        } else {
            disableNightMode()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeEnabled), name: .nightModeOn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeDisabled), name: .nightModeOff, object: nil)
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
        
        upvoteTint = ResourcesDay.UPVOTE_TINT_COLOR
        downvoteTint = ResourcesDay.DOWNVOTE_TINT_COLOR
        commentTint = ResourcesDay.COMMENT_TINT_COLOR
        saveTint = ResourcesDay.SAVE_TINT_COLOR
        shareTint = ResourcesDay.SHARE_TINT_COLOR
    }
    
    override func viewWillAppear(_ animated: Bool) {
        spinner = displaySpinner()
        
        dataSource.observeSingleArticle(articleId: articleId!) { (retrievedArticle) in
            self.article = retrievedArticle
            
            if (self.article?.type)! == "article" {
                self.genHtml()
            } else {
                let link = URL(string: (self.article?.link)!)
                let request = URLRequest(url: link!)
                self.webView.load(request)
            }
            
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
        }
    }
    
    func genHtml() {
        let htmlUtils = HtmlUtils()
        let baseUrlPattern = try? NSRegularExpression(pattern:"(https?://.*?/).*", options: .caseInsensitive)
        let baseUrl = baseUrlPattern?.stringByReplacingMatches(in: (article?.link)!, options: [], range: NSMakeRange(0, (article?.link)!.count), withTemplate: "$1")
        let generatedHtml = htmlUtils.regenArticleHtml((article?.link)!, (article?.title)!, (article?.author)!, (article?.source)!, DateUtils.parsePrettyDate(unixTimestamp: (article?.pubDate)!))
        
        let isSuccessful = generatedHtml != nil && !(generatedHtml?.isEmpty)!
        
        if isSuccessful {
            if article?.readTime == nil {
                let wordCount = generatedHtml?.split(separator: " ").count
                let readTime = Int(ceil(Double(wordCount!) / 200.0))
                dataSource.setArticleReadTime(article: self.article!, readTime: readTime)
            }
            
            webView.loadHTMLString(generatedHtml!, baseURL: URL(string: baseUrl!))
        } else {
            dismiss(animated: true, completion: nil)
            if let vc = feedVC {
                vc.view.makeToast("Failed to load article")
            } else if let vc = searchVC {
                vc.view.makeToast("Failed to load article")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        if let spinner = spinner {
            removeSpinner(spinner)
        }
    }

    @IBAction func didTapBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapSearchButton(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            self.searchBar.isHidden = !self.searchBar.isHidden
        }
        if searchBar.isHidden {
            searchBar.resignFirstResponder()
        } else {
            searchBar.becomeFirstResponder()
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
        if !isUserEmailVerified(user: user) {
            showEmailVerificationAlert(user: user)
            return
        }
        
        upvoteButton.isEnabled = false
        downvoteButton.isEnabled = false
        
        var wasUpvoted = false
        var wasDownvoted = false
        
        if let upvoters = article?.upvoters {
            if upvoters.keys.contains(uid) {
                wasUpvoted = true
            }
        }
        
        if let downvoters = article?.downvoters {
            if downvoters.keys.contains(uid) {
                wasDownvoted = true
            }
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dataSource.updateArticleVote(article: article!, actionIsUpvote: true, wasUpvoted: wasUpvoted, wasDownvoted: wasDownvoted) { dispatchGroup.leave() }
        
        dispatchGroup.enter()
        dataSource.updateUserVote(article: article!, actionIsUpvote: true) { dispatchGroup.leave() }
        dispatchGroup.notify(queue: .main) {
            
            self.upvoteButton.isEnabled = true
            self.downvoteButton.isEnabled = true
        }
    }
    
    @IBAction func didTapDownvoteButton(_ sender: Any) {
        if !isUserEmailVerified(user: user) {
            showEmailVerificationAlert(user: user)
            return
        }
        
        upvoteButton.isEnabled = false
        downvoteButton.isEnabled = false
        
        var wasUpvoted = false
        var wasDownvoted = false
        
        if let upvoters = article?.upvoters {
            if upvoters.keys.contains(uid) {
                wasUpvoted = true
            }
        }
        
        if let downvoters = article?.downvoters {
            if downvoters.keys.contains(uid) {
                wasDownvoted = true
            }
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dataSource.updateArticleVote(article: article!, actionIsUpvote: false, wasUpvoted: wasUpvoted, wasDownvoted: wasDownvoted) { dispatchGroup.leave() }
        
        dispatchGroup.enter()
        dataSource.updateUserVote(article: article!, actionIsUpvote: false) { dispatchGroup.leave() }
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
        if let shareLink = article?.link {
            
            let activityController = UIActivityViewController(activityItems: [URL(string: shareLink) ?? ""],  applicationActivities: nil)
            DispatchQueue.main.async {
                self.present(activityController, animated: true)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension WebViewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let spinner = self.spinner {
            self.removeSpinner(spinner)
        }
        
        if let path = Bundle.main.path(forResource: "UIWebViewSearch", ofType: "js"), let jsString = try? String(contentsOfFile: path, encoding: .utf8) {
            self.webView.evaluateJavaScript(jsString) { (result, error) in
                if let error = error {
                    
                    return
                }
            }
        }
    }
}

extension WebViewViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let startSearch = "uiWebview_HighlightAllOccurrencesOfString('\(searchText)')"
        
        webView.evaluateJavaScript(startSearch) { (result, error) in
            if let error = error {
                
                return
            }
            
            self.webView.evaluateJavaScript("uiWebview_SearchResultCount") { (count, error) in
                if let error = error {
                    
                    return
                }
                
                self.resultCount = count as! Int
                self.searchIndex = self.resultCount
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchIndex < 1 {
            self.view.makeToast("You've reached the end of the article!")
            searchIndex = resultCount
        } else {
            let goToNext = "uiWebview_ScrollTo('\(searchIndex)')"
            webView.evaluateJavaScript(goToNext)
            searchIndex -= 1
        }
    }
}
