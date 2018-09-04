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

class SearchHitsTvCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var voteCntImageView: UIImageView!
    @IBOutlet weak var voteCntLabel: UILabel!
    @IBOutlet weak var commCntLabel: UILabel!
    @IBOutlet weak var mainImageView: UIImageView!
    
    @IBOutlet weak var titleHeightConstraint: NSLayoutConstraint!
    
    var hit: [String: Any]? {
        didSet {
            guard let hit = self.hit else { return }
            
            titleLabel.highlightedText = SearchResults.highlightResult(hit: hit, path: "title")?.value
            titleLabel.highlightedTextColor = Resources.SEARCH_HIT_TEXT_COLOR
            titleLabel.highlightedBackgroundColor = Resources.SEARCH_HIT_BG_COLOR
            
            sourceLabel.highlightedText = SearchResults.highlightResult(hit: hit, path: "source")?.value
            sourceLabel.highlightedTextColor = Resources.SEARCH_HIT_TEXT_COLOR
            sourceLabel.highlightedBackgroundColor = Resources.SEARCH_HIT_BG_COLOR
            
            if let hitDate = hit["pubDate"] as? Double {
                dateLabel.text = DateUtils.parsePrettyDate(unixTimestamp: hitDate)
            }
            
            let voteCnt = hit["voteCount"] as? Int ?? 0
            voteCntLabel.text = String(voteCnt)
            if voteCnt < 0 {
                voteCntImageView.tintColor = Resources.DOWNVOTE_TINT_COLOR
                voteCntImageView.image = #imageLiteral(resourceName: "ic_arrow_down")
            }
            
            let commCnt = hit["commentCount"] as? Int ?? 0
            commCntLabel.text = String(commCnt)
            
            var imageUrl: String?
            if let url = hit["imageUrl"] as? String {
                imageUrl = url
            }
            if imageUrl == nil || imageUrl == "" {
                if let url = hit["postImageUrl"] as? String {
                    imageUrl = url
                }
            }
            if imageUrl != nil && imageUrl != "" {
                mainImageView.sd_setImage(with: URL(string: imageUrl!))
            } else {
                mainImageView.isHidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.lightGray.cgColor
    }

    override func prepareForReuse() {
        titleLabel.text = nil
        sourceLabel.text = nil
        dateLabel.text = nil
        voteCntImageView.image = #imageLiteral(resourceName: "ic_arrow_up")
        voteCntImageView.tintColor = Resources.UPVOTE_TINT_COLOR
        voteCntLabel.text = nil
        commCntLabel.text = nil
        mainImageView.isHidden = false
        mainImageView.sd_cancelCurrentImageLoad()
    }

}
