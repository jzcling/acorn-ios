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

class WebViewViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    @IBOutlet weak var optionsButton: UIBarButtonItem!
    @IBOutlet weak var upvoteButton: BounceButton!
    @IBOutlet weak var downvoteButton: BounceButton!
    @IBOutlet weak var commentButton: BounceButton!
    @IBOutlet weak var saveButton: BounceButton!
    @IBOutlet weak var shareButton: BounceButton!
    
    var article: Article?
    
    var feedVC: FeedViewController?
    var searchVC: SearchViewController?
    
    lazy var user = Auth.auth().currentUser!
    lazy var uid = user.uid
    
    let dataSource = DataSource.instance
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    var spinner: UIView?
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner = displaySpinner()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        if (article?.type)! == "article" {
            genHtml()
            dispatchGroup.leave()
        } else {
            let link = URL(string: (article?.link)!)
            let request = URLRequest(url: link!)
            webView.load(request)
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            if let spinner = self.spinner {
                self.removeSpinner(spinner)
            }
        }
        
        dataSource.observeSingleArticle(article: article!) { (retrievedArticle) in
            self.article = retrievedArticle
            if let upvoters = self.article?.upvoters {
                if upvoters.keys.contains(self.uid) {
                    self.upvoteButton.tintColor = Resources.UPVOTE_TINT_COLOR
                }
            }
            
            if let downvoters = self.article?.downvoters {
                if downvoters.keys.contains(self.uid) {
                    self.downvoteButton.tintColor = Resources.DOWNVOTE_TINT_COLOR
                }
            }
            
            if let commenters = self.article?.commenters {
                if commenters.keys.contains(self.uid) {
                    self.commentButton.tintColor = Resources.COMMENT_TINT_COLOR
                }
            }
            
            if let savers = self.article?.savers {
                if savers.keys.contains(self.uid) {
                    self.saveButton.tintColor = Resources.SAVE_TINT_COLOR
                }
            }
            
            if let sharers = self.article?.sharers {
                if sharers.keys.contains(self.uid) {
                    self.shareButton.tintColor = Resources.SHARE_TINT_COLOR
                }
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
    
    @IBAction func didTapUpvoteButton(_ sender: Any) {
        checkEmailVerified(user: user)
        
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
            print("upvote: complete")
            self.upvoteButton.isEnabled = true
            self.downvoteButton.isEnabled = true
        }
    }
    
    @IBAction func didTapDownvoteButton(_ sender: Any) {
        checkEmailVerified(user: user)
        
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
            print("downvote: complete")
            self.upvoteButton.isEnabled = true
            self.downvoteButton.isEnabled = true
        }
    }
    
    @IBAction func didTapCommentButton(_ sender: Any) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Comment") as? CommentViewController
        vc?.article = article
        let _ = vc?.view
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
            print("save: complete")
            self.saveButton.isEnabled = true
        }
    }
    
    @IBAction func didTapShareButton(_ sender: Any) {
        if let shareLink = article?.link {
            print(shareLink)
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
