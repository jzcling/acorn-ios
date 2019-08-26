//
//  VideoFeedCvCell.swift
//  Acorn
//
//  Created by macOS on 29/10/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import MaterialComponents
import SDWebImage
import FirebaseUI
import Firebase

class VideoFeedCvCell: UICollectionViewCell {
    
    @IBOutlet weak var newBannerImageView: UIImageView!
    @IBOutlet weak var themeLabel: UILabel!
    @IBOutlet weak var topSeparatorLabel: UILabel!
    @IBOutlet weak var youtubeViewCountLabel: UILabel!
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
    
    weak var delegate: VideoFeedCvCellDelegate?
    
    var video: Video?
    var textColor: UIColor?
    var textColorFaint: UIColor?
    var textColorRead: UIColor?
    
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
    
    let defaults = UserDefaults.standard
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let inkTouchController = MDCInkTouchController(view: self)
        inkTouchController.addInkView()
        
        self.layer.cornerRadius = 10
        
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openVideo)))
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openVideo)))
        
        commentButton.isEnabled = false
        saveButton.isEnabled = false
        
        if optionsButton != nil {
            let hasSeenOptions = defaults.bool(forKey: "hasSeenVideoOptions")
            if !hasSeenOptions {
                optionsButton.tintColor = UIColor.red
            } else {
                optionsButton.tintColor = buttonDefaultTint
            }
        }
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
        
        imageView.sd_cancelCurrentImageLoad()
        
        upvoteButton.tintColor = buttonDefaultTint
        downvoteButton.tintColor = buttonDefaultTint
        commentButton.tintColor = buttonDefaultTint
        saveButton.tintColor = buttonDefaultTint
        shareButton.tintColor = buttonDefaultTint
        
        if optionsButton != nil {
            let hasSeenOptions = defaults.bool(forKey: "hasSeenVideoOptions")
            if !hasSeenOptions {
                optionsButton.tintColor = UIColor.red
            } else {
                optionsButton.tintColor = buttonDefaultTint
            }
        }
        
        dataSource.removeVideoObserver(video!.objectID)
    }
    
    func populateCell(video: Video) {
        if let seenBy = video.seenBy?.keys, seenBy.contains(uid) {
            newBannerImageView.isHidden = true
        } else {
            newBannerImageView.isHidden = false
        }
        if (video.mainTheme == nil || video.mainTheme == "") {
            themeLabel.isHidden = true
            topSeparatorLabel.isHidden = true
        } else {
            themeLabel.isHidden = false
            topSeparatorLabel.isHidden = false
            themeLabel.text = video.mainTheme
            topSeparatorLabel.text = " • "
            themeLabel.sizeToFit()
        }
        if video.youtubeViewCount != nil {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
            let formattedCount = numberFormatter.string(from: NSNumber(value: video.youtubeViewCount!))
            youtubeViewCountLabel.text = "\(formattedCount ?? "0") YouTube views"
            youtubeViewCountLabel.sizeToFit()
        } else {
            youtubeViewCountLabel.text = ""
        }
        if let viewedBy = video.viewedBy?.keys, viewedBy.contains(uid) {
            titleLabel.textColor = textColorRead
        } else {
            titleLabel.textColor = textColor
        }
        titleLabel.text = video.title
        sourceLabel.text = video.source
        dateLabel.text = DateUtils.parsePrettyDate(unixTimestamp: -video.pubDate)
        if (video.voteCount != nil && video.voteCount! < 0) {
            netVoteImageView.image = #imageLiteral(resourceName: "ic_arrow_down_18")
            netVoteImageView.tintColor = downvoteTint
        } else {
            netVoteImageView.tintColor = upvoteTint
        }
        voteCntLabel.text = String(video.voteCount != nil ? video.voteCount! : 0)
        commCntImageView.tintColor = commentTint
        commCntLabel.text = String(video.commentCount != nil ? video.commentCount! : 0)
        let videoId = (video.youtubeVideoId != nil) ? video.youtubeVideoId! : String(video.objectID.suffix(11))
        let thumbnailUrl = "https://img.youtube.com/vi/" + videoId + "/hqdefault.jpg";
        imageView.sd_setImage(with: URL(string: thumbnailUrl))
        
        themeLabel.textColor = textColorFaint
        topSeparatorLabel.textColor = textColorFaint
        youtubeViewCountLabel.textColor = textColorFaint
        titleLabel.textColor = textColor
        sourceLabel.textColor = textColor
        dateLabel.textColor = textColor
        voteCntLabel.textColor = textColor
        commCntLabel.textColor = textColor
        sourceDateSeparator.textColor = textColor
        voteCommSeparator.textColor = textColor
        
        if let upvoters = video.upvoters {
            if upvoters.keys.contains(uid) {
                upvoteButton.tintColor = upvoteTint
            } else {
                upvoteButton.tintColor = buttonDefaultTint
            }
        }
        
        if let downvoters = video.downvoters {
            if downvoters.keys.contains(uid) {
                downvoteButton.tintColor = downvoteTint
            } else {
                downvoteButton.tintColor = buttonDefaultTint
            }
        }
        
        if let commenters = video.commenters {
            if commenters.keys.contains(uid) {
                commentButton.tintColor = commentTint
            } else {
                commentButton.tintColor = buttonDefaultTint
            }
        }
        
        if let savers = video.savers {
            if savers.keys.contains(uid) {
                saveButton.tintColor = saveTint
            } else {
                saveButton.tintColor = buttonDefaultTint
            }
        }
        
        if let sharers = video.sharers {
            if sharers.keys.contains(uid) {
                shareButton.tintColor = shareTint
            } else {
                shareButton.tintColor = buttonDefaultTint
            }
        }
    }
    
    @IBAction func didTapUpvoteButton(_ sender: Any) {
        delegate?.upvoteActionTapped(video: video!, upvoteButton: upvoteButton, downvoteButton: downvoteButton)
    }
    
    @IBAction func didTapDownvoteButton(_ sender: Any) {
        delegate?.downvoteActionTapped(video: video!, upvoteButton: upvoteButton, downvoteButton: downvoteButton)
    }
    
    @IBAction func didTapCommentButton(_ sender: Any) {
        delegate?.openComments((self.video?.objectID)!)
    }
    
    @objc func openVideo() {
        dataSource.recordOpenVideoDetails(videoId: (self.video?.objectID)!)
        delegate?.openVideo(self.video!)
    }
    
    @IBAction func didTapSaveButton(_ sender: Any) {
        delegate?.saveActionTapped(video: video!, saveButton: saveButton)
    }
    
    @IBAction func didTapShareButton(_ sender: Any) {
        guard let video = self.video else { return }
        let url = ShareUtils.createVideoShareUri(videoId: video.objectID, sharerId: uid)
        ShareUtils.createShortDynamicLink(url: url, sharerId: uid) { (dynamicLink) in
            self.delegate?.openShareActivity(dynamicLink, video)
        }
    }
    
    @IBAction func didTapOptionsButton(_ sender: Any) {
        delegate?.openOptions(anchor: optionsButton, video: self.video!)
    }
    
}
