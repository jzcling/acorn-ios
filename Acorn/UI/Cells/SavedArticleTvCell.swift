//
//  SavedArticleTvCell.swift
//  Acorn
//
//  Created by macOS on 11/10/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit

class SavedArticleTvCell: UITableViewCell {

    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var voteCntImageView: UIImageView!
    @IBOutlet weak var voteCntLabel: UILabel!
    @IBOutlet weak var commCntImageView: UIImageView!
    @IBOutlet weak var commCntLabel: UILabel!
    @IBOutlet weak var mainImageView: UIImageView!
    
    @IBOutlet weak var sourceDateSeparator: UILabel!
    @IBOutlet weak var voteCommSeparator: UILabel!
    
    @IBOutlet weak var titleHeightConstraint: NSLayoutConstraint!
    
    var cellTextColor: UIColor?
    
    let nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    lazy var upvoteTint = nightModeOn ? ResourcesNight.UPVOTE_TINT_COLOR : ResourcesDay.UPVOTE_TINT_COLOR
    lazy var downvoteTint = nightModeOn ? ResourcesNight.DOWNVOTE_TINT_COLOR : ResourcesDay.DOWNVOTE_TINT_COLOR
    lazy var commentTint = nightModeOn ? ResourcesNight.COMMENT_TINT_COLOR : ResourcesDay.COMMENT_TINT_COLOR
    lazy var cardBackgroundColor = nightModeOn ? ResourcesNight.CARD_BG_COLOR : ResourcesDay.CARD_BG_COLOR
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mainImageView.layer.cornerRadius = 10
    }
    
    func populateCell(article: Article) {
        cellView.backgroundColor = cardBackgroundColor
        self.contentView.backgroundColor = cardBackgroundColor
        
        if article.link != nil && article.link != "" {
            titleLabel.text = article.title
            sourceLabel.text = article.source
        } else {
            titleLabel.text = article.postText
            sourceLabel.text = article.postAuthor
        }
        
        dateLabel.text = DateUtils.parsePrettyDate(unixTimestamp: -article.pubDate)
        
        let voteCnt = article.voteCount ?? 0
        voteCntLabel.text = String(voteCnt)
        if voteCnt < 0 {
            voteCntImageView.tintColor = downvoteTint
            voteCntImageView.image = #imageLiteral(resourceName: "ic_arrow_down_18")
        } else {
            voteCntImageView.tintColor = upvoteTint
        }
        
        commCntImageView.tintColor = commentTint
        
        let commCnt = article.commentCount ?? 0
        commCntLabel.text = String(commCnt)
        
        var imageUrl: String?
        if let url = article.imageUrl {
            imageUrl = url
        }
        if imageUrl == nil || imageUrl == "" {
            if let url = article.postImageUrl {
                imageUrl = url
            }
        }
        if imageUrl != nil && imageUrl != "" {
            mainImageView.sd_setImage(with: URL(string: imageUrl!))
        } else {
            mainImageView.isHidden = true
        }
        
        titleLabel.textColor = cellTextColor
        sourceLabel.textColor = cellTextColor
        dateLabel.textColor = cellTextColor
        voteCntLabel.textColor = cellTextColor
        commCntLabel.textColor = cellTextColor
        sourceDateSeparator.textColor = cellTextColor
        voteCommSeparator.textColor = cellTextColor
    }
    
    override func prepareForReuse() {
        titleLabel.text = nil
        sourceLabel.text = nil
        dateLabel.text = nil
        voteCntImageView.image = #imageLiteral(resourceName: "ic_arrow_up_18")
        voteCntImageView.tintColor = upvoteTint
        voteCntLabel.text = nil
        commCntLabel.text = nil
        mainImageView.isHidden = false
        mainImageView.sd_cancelCurrentImageLoad()
    }
}
