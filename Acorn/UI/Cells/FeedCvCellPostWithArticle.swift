//
//  FeedCvCellPostWithArticle.swift
//  Acorn
//
//  Created by macOS on 9/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import MaterialComponents
import SDWebImage
import FirebaseUI
import Firebase

class FeedCvCellPostWithArticle: UICollectionViewCell {

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
    @IBOutlet weak var articleCardView: UIView!
    @IBOutlet weak var articleImageView: UIImageView!
    @IBOutlet weak var articleTitleLabel: UILabel!
    @IBOutlet weak var articleSourceLabel: UILabel!
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
        
        articleCardView.layer.cornerRadius = 10
        articleCardView.layer.borderWidth = 1.0
        articleCardView.layer.borderColor = UIColor.clear.cgColor
        articleCardView.layer.shadowColor = UIColor.gray.cgColor
        articleCardView.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        articleCardView.layer.shadowRadius = 4.0
        articleCardView.layer.shadowOpacity = 1.0
        articleCardView.layer.masksToBounds = false
        articleCardView.layer.shadowPath = UIBezierPath(roundedRect: articleCardView.bounds, cornerRadius: articleCardView.layer.cornerRadius).cgPath
        
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        
        articleCardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openArticle)))
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openComments)))
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        topSeparatorLabel.text = " • "
        readTimeLabel.text = nil
        
        articleTitleLabel.text = nil
        articleSourceLabel.text = nil
        articleImageView.sd_cancelCurrentImageLoad()
        
        upvoteButton.tintColor = buttonDefaultTint
        downvoteButton.tintColor = buttonDefaultTint
        commentButton.tintColor = buttonDefaultTint
        saveButton.tintColor = buttonDefaultTint
        shareButton.tintColor = buttonDefaultTint
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
        if article.link != nil && article.link != "" {
            articleImageView.sd_setImage(with: URL(string: article.imageUrl!))
            articleTitleLabel.text = article.title
            articleTitleLabel.sizeToFit()
            articleSourceLabel.text = article.source
        } else {
            if article.postImageUrl!.starts(with: "gs://") {
                let ref = Storage.storage().reference(forURL: article.postImageUrl!)
                articleImageView.sd_setImage(with: ref)
            } else {
                articleImageView.sd_setImage(with: URL(string: article.postImageUrl!))
            }
            articleTitleLabel.text = article.title
            articleSourceLabel.text = nil
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
        articleTitleLabel.textColor = textColor
        articleSourceLabel.textColor = textColor
        
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
    
    @IBAction func didTapSaveButton(_ sender: Any) {
        delegate?.saveActionTapped(article: article!, saveButton: saveButton)
    }
    
    @IBAction func didTapShareButton(_ sender: Any) {
        guard let article = self.article else { return }
        let url = ShareUtils.createShareUri(articleId: article.objectID, url: article.link!, sharerId: uid!)
        ShareUtils.createShortDynamicLink(url: url, sharerId: uid!) { (dynamicLink) in
            self.delegate?.openShareActivity(dynamicLink, article)
        }
    }

    @objc func openArticle() {
        dataSource.recordOpenArticleDetails(articleId: (self.article?.objectID)!, mainTheme: self.article?.mainTheme ?? "General")
        delegate?.openArticle((self.article?.objectID)!)
    }
    
    @objc func openComments() {
        delegate?.openComments((self.article?.objectID)!)
    }
    
    @IBAction func didTapOptionsButton(_ sender: Any) {
        delegate?.openOptions(anchor: optionsButton, post: article!)
    }
    
}
