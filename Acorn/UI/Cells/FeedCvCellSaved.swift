//
//  FeedCvCellSaved.swift
//  Acorn
//
//  Created by macOS on 3/9/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import SDWebImage
import MaterialComponents

class FeedCvCellSaved: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var voteCntImageView: UIImageView!
    @IBOutlet weak var voteCntLabel: UILabel!
    @IBOutlet weak var commCntLabel: UILabel!
    @IBOutlet weak var mainImageView: UIImageView!
    
    @IBOutlet weak var titleHeightConstraint: NSLayoutConstraint!
    
    var delegate: FeedCvCellDelegate?
    
    var article: Article?
    
    func populateCell(article: Article) {
        titleLabel.text = article.title
        
        sourceLabel.text = article.source
        
        dateLabel.text = DateUtils.parsePrettyDate(unixTimestamp: article.pubDate)
        
        let voteCnt = article.voteCount ?? 0
        voteCntLabel.text = String(voteCnt)
        if voteCnt < 0 {
            voteCntImageView.tintColor = Resources.DOWNVOTE_TINT_COLOR
            voteCntImageView.image = #imageLiteral(resourceName: "ic_arrow_down")
        }
        
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
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let inkTouchController = MDCInkTouchController(view: self)
        inkTouchController.addInkView()
        
        self.layer.cornerRadius = 6
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cellTapped)))
        
        mainImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cellTapped)))
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
    
    @objc func cellTapped() {
        if article?.link != nil && article?.link != "" {
            delegate?.openArticle(self)
        } else {
            delegate?.openComments(self)
        }
    }
}
