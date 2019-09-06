//
//  FeedCvCellPost.swift
//  Acorn
//
//  Created by macOS on 9/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import MaterialComponents
import SDWebImage
import FirebaseUI
import Firebase

class FeedCvCellPost: UICollectionViewCell {

    @IBOutlet weak var newBannerImageView: UIImageView!
    @IBOutlet weak var themeLabel: UILabel!
    @IBOutlet weak var topSeparatorLabel: UILabel!
    @IBOutlet weak var readTimeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var netVoteImageView: UIImageView!
    @IBOutlet weak var voteCntLabel: UILabel!
    @IBOutlet weak var commCntImageView: UIImageView!
    @IBOutlet weak var commCntLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var downvoteButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var optionsButton: UIButton!
    
    @IBOutlet weak var sourceDateSeparator: UILabel!
    @IBOutlet weak var voteCommSeparator: UILabel!
    
    @IBOutlet weak var sourceLabelWidthConstraint: NSLayoutConstraint!
    
    weak var delegate: FeedCvCellDelegate?
    
    var article: Article?
    var textColor: UIColor?
    var textColorFaint: UIColor?
    var textColorRead: UIColor?
    
    var uid: String?
    
    let dataSource = NetworkDataSource.instance
    
    let nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    lazy var upvoteTint = nightModeOn ? ResourcesNight.UPVOTE_TINT_COLOR : ResourcesDay.UPVOTE_TINT_COLOR
    lazy var downvoteTint = nightModeOn ? ResourcesNight.DOWNVOTE_TINT_COLOR : ResourcesDay.DOWNVOTE_TINT_COLOR
    lazy var commentTint = nightModeOn ? ResourcesNight.COMMENT_TINT_COLOR : ResourcesDay.COMMENT_TINT_COLOR
    lazy var saveTint = nightModeOn ? ResourcesNight.SAVE_TINT_COLOR : ResourcesDay.SAVE_TINT_COLOR
    lazy var shareTint = nightModeOn ? ResourcesNight.SHARE_TINT_COLOR : ResourcesDay.SHARE_TINT_COLOR
    lazy var buttonDefaultTint = nightModeOn ? ResourcesNight.BUTTON_DEFAULT_TINT_COLOR : ResourcesDay.BUTTON_DEFAULT_TINT_COLOR
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let inkTouchController = MDCInkTouchController(view: self)
        inkTouchController.addInkView()
        
        self.layer.cornerRadius = 10
        
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openComments)))
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openImage)))
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        topSeparatorLabel.text = " • "
        readTimeLabel.text = nil
        
        imageView.sd_cancelCurrentImageLoad()
        
        upvoteButton.tintColor = buttonDefaultTint
        downvoteButton.tintColor = buttonDefaultTint
        commentButton.tintColor = buttonDefaultTint
        saveButton.tintColor = buttonDefaultTint
        shareButton.tintColor = buttonDefaultTint
        optionsButton.tintColor = buttonDefaultTint
    }
    
    func populateContent(article: Article, selectedFeed: String) {
        self.article = article
        populateCell(article: self.article!)
    }
    
    func populateCell(article: Article) {
        if let seenBy = article.seenBy?.keys, seenBy.contains(uid!) {
            newBannerImageView.isHidden = true
        } else {
            newBannerImageView.isHidden = false
        }
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
        if let openedBy = article.openedBy?.keys, openedBy.contains(uid!) {
            titleLabel.textColor = textColorRead
        } else {
            titleLabel.textColor = textColor
        }
        titleLabel.text = article.postText
        sourceLabel.text = article.postAuthor
        dateLabel.text = DateUtils.parsePrettyDate(unixTimestamp: -article.postDate!)
        if (article.voteCount != nil && article.voteCount! < 0) {
            netVoteImageView.image = #imageLiteral(resourceName: "ic_arrow_down_18")
            netVoteImageView.tintColor = downvoteTint
        } else {
            netVoteImageView.tintColor = upvoteTint
        }
        voteCntLabel.text = String(article.voteCount != nil ? article.voteCount! : 0)
        commCntImageView.tintColor = commentTint
        commCntLabel.text = String(article.commentCount != nil ? article.commentCount! : 0)
        if article.postImageUrl!.starts(with: "gs://") {
            let ref = Storage.storage().reference(forURL: article.postImageUrl!)
            imageView.sd_setImage(with: ref)
        } else {
            imageView.sd_setImage(with: URL(string: article.postImageUrl!))
        }
        
        themeLabel.textColor = textColorFaint
        topSeparatorLabel.textColor = textColorFaint
        readTimeLabel.textColor = textColorFaint
        titleLabel.textColor = textColor
        sourceLabel.textColor = textColor
        dateLabel.textColor = textColor
        voteCntLabel.textColor = textColor
        commCntLabel.textColor = textColor
        sourceDateSeparator.textColor = textColor
        voteCommSeparator.textColor = textColor
        
        if let upvoters = article.upvoters {
            if upvoters.keys.contains(uid!) {
                upvoteButton.tintColor = upvoteTint
            } else {
                upvoteButton.tintColor = buttonDefaultTint
            }
        }
        
        if let downvoters = article.downvoters {
            if downvoters.keys.contains(uid!) {
                downvoteButton.tintColor = downvoteTint
            } else {
                downvoteButton.tintColor = buttonDefaultTint
            }
        }
        
        if let commenters = article.commenters {
            if commenters.keys.contains(uid!) {
                commentButton.tintColor = commentTint
            } else {
                commentButton.tintColor = buttonDefaultTint
            }
        }
        
        if let savers = article.savers {
            if savers.keys.contains(uid!) {
                saveButton.tintColor = saveTint
            } else {
                saveButton.tintColor = buttonDefaultTint
            }
        }
        
        if let sharers = article.sharers {
            if sharers.keys.contains(uid!) {
                shareButton.tintColor = shareTint
            } else {
                shareButton.tintColor = buttonDefaultTint
            }
        }
    }
    
    @IBAction func didTapUpvoteButton(_ sender: Any) {
        delegate?.upvoteActionTapped(article: article!, upvoteButton: upvoteButton, downvoteButton: downvoteButton)
    }
    
    @IBAction func didTapDownvoteButton(_ sender: Any) {
        delegate?.downvoteActionTapped(article: article!, upvoteButton: upvoteButton, downvoteButton: downvoteButton)
    }
    
    @IBAction func didTapCommentButton(_ sender: Any) {
        openComments()
    }
    
    @objc func openComments() {
        delegate?.openComments((self.article?.objectID)!)
    }
    
    @IBAction func didTapSaveButton(_ sender: Any) {
        delegate?.saveActionTapped(article: article!, saveButton: saveButton)
    }
    
    @IBAction func didTapShareButton(_ sender: Any) {
    }
    
    @objc func openImage() {
        delegate?.openImage(self.article?.link)
    }
    
    @IBAction func didTapOptionsButton(_ sender: Any) {
        delegate?.openOptions(anchor: optionsButton, post: article!)
    }
    
}
