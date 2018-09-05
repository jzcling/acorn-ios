//
//  FeedCvCellPostNoImage.swift
//  Acorn
//
//  Created by macOS on 9/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import MaterialComponents
import FirebaseUI
import Firebase

class FeedCvCellPostNoImage: UICollectionViewCell {

    @IBOutlet weak var themeLabel: UILabel!
    @IBOutlet weak var topSeparatorLabel: UILabel!
    @IBOutlet weak var readTimeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var netVoteImageView: UIImageView!
    @IBOutlet weak var voteCntLabel: UILabel!
    @IBOutlet weak var commCntLabel: UILabel!
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var downvoteButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    weak var delegate: FeedCvCellDelegate?
    
    var article: Article?
    
    lazy var user = Auth.auth().currentUser!
    lazy var uid = user.uid
    
    let dataSource = DataSource.instance
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let inkTouchController = MDCInkTouchController(view: self)
        inkTouchController.addInkView()
        
        self.layer.cornerRadius = 6
        
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openComments)))
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        themeLabel.text = nil
        topSeparatorLabel.text = " • "
        readTimeLabel.text = nil
        titleLabel.text = nil
        sourceLabel.text = nil
        dateLabel.text = nil
        netVoteImageView.image = #imageLiteral(resourceName: "ic_arrow_up")
        netVoteImageView.tintColor = Resources.UPVOTE_TINT_COLOR
        voteCntLabel.text = "0"
        commCntLabel.text = "0"
        upvoteButton.tintColor = Resources.BUTTON_DEFAULT_TINT_COLOR
        downvoteButton.tintColor = Resources.BUTTON_DEFAULT_TINT_COLOR
        commentButton.tintColor = Resources.BUTTON_DEFAULT_TINT_COLOR
        saveButton.tintColor = Resources.BUTTON_DEFAULT_TINT_COLOR
        shareButton.tintColor = Resources.BUTTON_DEFAULT_TINT_COLOR
        dataSource.removeArticleObserver(article: article!)
    }

    func populateContent(article: Article, selectedFeed: String) {
        if selectedFeed == "Subscriptions" {
            dataSource.observeSingleArticle(article: article) { (retrievedArticle) in
                self.article = retrievedArticle
                self.populateCell(article: self.article!)
            }
        } else {
            self.article = article
            populateCell(article: self.article!)
        }
    }
    
    func populateCell(article: Article) {
        themeLabel.text = article.mainTheme
        themeLabel.sizeToFit()
        if article.readTime != nil {
            topSeparatorLabel.text = " • "
            readTimeLabel.text = String(article.readTime!) + "m read"
            readTimeLabel.sizeToFit()
        } else {
            readTimeLabel.text = ""
            topSeparatorLabel.text = ""
        }
        titleLabel.text = article.postText
        sourceLabel.text = article.postAuthor
        dateLabel.text = DateUtils.parsePrettyDate(unixTimestamp: -article.postDate!)
        if (article.voteCount != nil && article.voteCount! < 0) {
            netVoteImageView.image = #imageLiteral(resourceName: "ic_arrow_down")
            netVoteImageView.tintColor = Resources.DOWNVOTE_TINT_COLOR
        }
        voteCntLabel.text = String(article.voteCount != nil ? article.voteCount! : 0)
        commCntLabel.text = String(article.commentCount != nil ? article.commentCount! : 0)
        
        if let upvoters = article.upvoters {
            if upvoters.keys.contains(uid) {
                upvoteButton.tintColor = Resources.UPVOTE_TINT_COLOR
            }
        }
        
        if let downvoters = article.downvoters {
            if downvoters.keys.contains(uid) {
                downvoteButton.tintColor = Resources.DOWNVOTE_TINT_COLOR
            }
        }
        
        if let commenters = article.commenters {
            if commenters.keys.contains(uid) {
                commentButton.tintColor = Resources.COMMENT_TINT_COLOR
            }
        }
        
        if let savers = article.savers {
            if savers.keys.contains(uid) {
                saveButton.tintColor = Resources.SAVE_TINT_COLOR
            }
        }
        
        if let sharers = article.sharers {
            if sharers.keys.contains(uid) {
                shareButton.tintColor = Resources.SHARE_TINT_COLOR
            }
        }
    }
    
    @IBAction func didTapUpvoteButton(_ sender: Any) {
        delegate?.checkEmailVerified(user: user)
        
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
        delegate?.checkEmailVerified(user: user)
        
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
        openComments()
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
    }
    
    @objc func openComments() {
        delegate?.openComments(self)
    }
}
