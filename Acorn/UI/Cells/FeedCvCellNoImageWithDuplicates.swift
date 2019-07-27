//
//  FeedCvCellNoImageWithDuplicates.swift
//  Acorn
//
//  Created by Jeremy Ling on 22/7/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import MaterialComponents
import FirebaseUI
import Firebase

class FeedCvCellNoImageWithDuplicates: UICollectionViewCell {
    
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
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var downvoteButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBOutlet weak var sourceDateSeparator: UILabel!
    @IBOutlet weak var voteCommSeparator: UILabel!
    
    @IBOutlet weak var sourceLabelWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var duplicatesCollectionView: UICollectionView!
    
    
    
    weak var delegate: FeedCvCellDelegate?
    
    var article: Article? {
        didSet {
            self.duplicatesCollectionView?.reloadData()
        }
    }
    var textColor: UIColor?
    var textColorFaint: UIColor?
    
    lazy var user = Auth.auth().currentUser!
    lazy var uid = user.uid
    
    let dataSource = DataSource.instance
    
    let nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    lazy var upvoteTint = nightModeOn ? ResourcesNight.UPVOTE_TINT_COLOR : ResourcesDay.UPVOTE_TINT_COLOR
    lazy var downvoteTint = nightModeOn ? ResourcesNight.DOWNVOTE_TINT_COLOR : ResourcesDay.DOWNVOTE_TINT_COLOR
    lazy var commentTint = nightModeOn ? ResourcesNight.COMMENT_TINT_COLOR : ResourcesDay.COMMENT_TINT_COLOR
    lazy var saveTint = nightModeOn ? ResourcesNight.SAVE_TINT_COLOR : ResourcesDay.SAVE_TINT_COLOR
    lazy var shareTint = nightModeOn ? ResourcesNight.SHARE_TINT_COLOR : ResourcesDay.SHARE_TINT_COLOR
    lazy var buttonDefaultTint = nightModeOn ? ResourcesNight.BUTTON_DEFAULT_TINT_COLOR : ResourcesDay.BUTTON_DEFAULT_TINT_COLOR
    lazy var bgColor = nightModeOn ? ResourcesNight.COLOR_BG : ResourcesDay.COLOR_BG
    lazy var cardBgColor = nightModeOn ? ResourcesNight.CARD_BG_COLOR : ResourcesDay.CARD_BG_COLOR
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let inkTouchController = MDCInkTouchController(view: self)
        inkTouchController.addInkView()
        
        self.layer.cornerRadius = 10
        
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openArticle)))
        
        duplicatesCollectionView.delegate = self
        duplicatesCollectionView.dataSource = self
        duplicatesCollectionView.backgroundColor = bgColor
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        setNeedsLayout()
        layoutIfNeeded()
        
        let size = contentView.systemLayoutSizeFitting(layoutAttributes.size)
        
        var frame = layoutAttributes.frame
        frame.size.height = ceil(size.height)
        layoutAttributes.frame = frame
        
        return layoutAttributes
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        topSeparatorLabel.text = " • "
        readTimeLabel.text = nil
        
        upvoteButton.tintColor = buttonDefaultTint
        downvoteButton.tintColor = buttonDefaultTint
        commentButton.tintColor = buttonDefaultTint
        saveButton.tintColor = buttonDefaultTint
        shareButton.tintColor = buttonDefaultTint
        
        dataSource.removeArticleObserver(article!.objectID)
    }
    
    func populateContent(article: Article, selectedFeed: String) {
        self.article = article
        populateCell(article: self.article!)
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
        titleLabel.text = article.title
        sourceLabel.text = article.source
        dateLabel.text = DateUtils.parsePrettyDate(unixTimestamp: -article.pubDate)
        if (article.voteCount != nil && article.voteCount! < 0) {
            netVoteImageView.image = #imageLiteral(resourceName: "ic_arrow_down_18")
            netVoteImageView.tintColor = downvoteTint
        } else {
            netVoteImageView.tintColor = upvoteTint
        }
        voteCntLabel.text = String(article.voteCount != nil ? article.voteCount! : 0)
        commCntImageView.tintColor = commentTint
        commCntLabel.text = String(article.commentCount != nil ? article.commentCount! : 0)
        
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
            if upvoters.keys.contains(uid) {
                upvoteButton.tintColor = upvoteTint
            } else {
                upvoteButton.tintColor = buttonDefaultTint
            }
        }
        
        if let downvoters = article.downvoters {
            if downvoters.keys.contains(uid) {
                downvoteButton.tintColor = downvoteTint
            } else {
                downvoteButton.tintColor = buttonDefaultTint
            }
        }
        
        if let commenters = article.commenters {
            if commenters.keys.contains(uid) {
                commentButton.tintColor = commentTint
            } else {
                commentButton.tintColor = buttonDefaultTint
            }
        }
        
        if let savers = article.savers {
            if savers.keys.contains(uid) {
                saveButton.tintColor = saveTint
            } else {
                saveButton.tintColor = buttonDefaultTint
            }
        }
        
        if let sharers = article.sharers {
            if sharers.keys.contains(uid) {
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
        delegate?.openComments((self.article?.objectID)!)
    }
    
    @IBAction func didTapSaveButton(_ sender: Any) {
        delegate?.saveActionTapped(article: article!, saveButton: saveButton)
    }
    
    @IBAction func didTapShareButton(_ sender: Any) {
        guard let article = self.article else { return }
        let url = ShareUtils.createShareUri(articleId: article.objectID, url: article.link!, sharerId: uid)
        ShareUtils.createShortDynamicLink(url: url, sharerId: uid) { (dynamicLink) in
            self.delegate?.openShareActivity(dynamicLink, article)
        }
    }
    
    @objc func openArticle() {
        dataSource.recordOpenArticleDetails(articleId: (self.article?.objectID)!, mainTheme: self.article?.mainTheme ?? "General")
        delegate?.openArticle((self.article?.objectID)!)
    }
}

extension FeedCvCellNoImageWithDuplicates: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.article!.duplicates?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DuplicateArticleCell", for: indexPath) as! DuplicateArticleCell
        
        cell.titleWidthConstraint.constant = self.layer.frame.width * 0.6
        
        cell.backgroundColor = cardBgColor
        cell.textColor = textColor
        cell.textColorFaint = textColorFaint
        
        let articleId = Array(article!.duplicates!.keys)[indexPath.item]
        cell.populateCell(articleId: articleId)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let articleId = Array(article!.duplicates!.keys)[indexPath.item]
        dataSource.recordOpenArticleDetails(articleId: articleId, mainTheme: self.article?.mainTheme ?? "General")
        delegate?.openArticle(articleId)
    }
}
