//
//  SearchHitsTvCell.swift
//  Acorn
//
//  Created by macOS on 3/9/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import InstantSearch
import SDWebImage
import Firebase

class SearchHitsTvCell: UITableViewCell {
    
    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var sourceDateSeparator: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var voteCntImageView: UIImageView!
    @IBOutlet weak var voteCntLabel: UILabel!
    @IBOutlet weak var voteCommSeparator: UILabel!
    @IBOutlet weak var commCntImageView: UIImageView!
    @IBOutlet weak var commCntLabel: UILabel!
    @IBOutlet weak var mainImageView: UIImageView!
    
    @IBOutlet weak var titleHeightConstraint: NSLayoutConstraint!
    
    let nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    lazy var searchHitTextColor = nightModeOn ? ResourcesNight.SEARCH_HIT_TEXT_COLOR : ResourcesDay.SEARCH_HIT_TEXT_COLOR
    lazy var searchHitBGColor = nightModeOn ? ResourcesNight.SEARCH_HIT_BG_COLOR : ResourcesDay.SEARCH_HIT_BG_COLOR
    lazy var upvoteTint = nightModeOn ? ResourcesNight.UPVOTE_TINT_COLOR : ResourcesDay.UPVOTE_TINT_COLOR
    lazy var downvoteTint = nightModeOn ? ResourcesNight.DOWNVOTE_TINT_COLOR : ResourcesDay.DOWNVOTE_TINT_COLOR
    lazy var commentTint = nightModeOn ? ResourcesNight.COMMENT_TINT_COLOR : ResourcesDay.COMMENT_TINT_COLOR
    var defaultTextColor: UIColor?
    
    var hit: [String: Any]? {
        didSet {
            guard let hit = self.hit else { return }
            
            titleLabel.highlightedText = SearchResults.highlightResult(hit: hit, path: "title")?.value
            titleLabel.textColor = defaultTextColor
            titleLabel.highlightedTextColor = searchHitTextColor
            titleLabel.highlightedBackgroundColor = searchHitBGColor
            
            sourceLabel.highlightedText = SearchResults.highlightResult(hit: hit, path: "source")?.value
            sourceLabel.textColor = defaultTextColor
            sourceLabel.highlightedTextColor = searchHitTextColor
            sourceLabel.highlightedBackgroundColor = searchHitBGColor
            
            sourceDateSeparator.textColor = defaultTextColor
            
            if let hitDate = hit["pubDate"] as? Double {
                dateLabel.text = DateUtils.parsePrettyDate(unixTimestamp: -hitDate)
                dateLabel.textColor = defaultTextColor
            }
            
            let voteCnt = hit["voteCount"] as? Int ?? 0
            voteCntLabel.text = String(voteCnt)
            voteCntLabel.textColor = defaultTextColor
            if voteCnt < 0 {
                voteCntImageView.tintColor = downvoteTint
                voteCntImageView.image = #imageLiteral(resourceName: "ic_arrow_down_18")
            } else {
                voteCntImageView.tintColor = upvoteTint
            }
            
            voteCommSeparator.textColor = defaultTextColor
            
            commCntImageView.tintColor = commentTint
            
            let commCnt = hit["commentCount"] as? Int ?? 0
            commCntLabel.text = String(commCnt)
            commCntLabel.textColor = defaultTextColor
            
            var imageUrl: String?
            var ref: StorageReference?
            if let url = hit["imageUrl"] as? String {
                imageUrl = url
            }
            if imageUrl == nil || imageUrl == "" {
                if let url = hit["postImageUrl"] as? String {
                    if url.starts(with: "gs://") {
                        ref = Storage.storage().reference(forURL: url)
                        mainImageView.sd_setImage(with: ref!)
                    } else {
                        imageUrl = url
                    }
                }
            }
            if imageUrl != nil && imageUrl != "" {
                mainImageView.sd_setImage(with: URL(string: imageUrl!))
            } else {
                if ref == nil {
                    mainImageView.isHidden = true
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.lightGray.cgColor
        
        mainImageView.layer.cornerRadius = 10
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
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
