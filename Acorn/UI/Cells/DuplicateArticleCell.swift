//
//  DuplicateArticleCell.swift
//  Acorn
//
//  Created by Jeremy Ling on 22/7/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import MaterialComponents
import SDWebImage
import FirebaseUI
import Firebase

class DuplicateArticleCell: UICollectionViewCell {
    
    @IBOutlet weak var relatedLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var separatorLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleWidthConstraint: NSLayoutConstraint!
    
    var articleId: String?
    let dataSource = NetworkDataSource.instance
    
    var textColor: UIColor?
    var textColorFaint: UIColor?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let inkTouchController = MDCInkTouchController(view: self)
        inkTouchController.addInkView()
        
        self.layer.cornerRadius = 10
        imageView.layer.cornerRadius = 10
    }
    
    override func prepareForReuse() {
        imageView.sd_cancelCurrentImageLoad()
        imageView.isHidden = false
    }
    
    func populateCell(articleId: String) {
        self.articleId = articleId
        dataSource.observeSingleArticle(articleId: articleId) { (article) in
            self.titleLabel.text = article.title
            self.sourceLabel.text = article.source
            self.dateLabel.text = DateUtils.parsePrettyDate(unixTimestamp: -article.pubDate)
            if (article.imageUrl != nil && article.imageUrl != "") {
                self.imageView.sd_setImage(with: URL(string: article.imageUrl!))
            } else {
                self.imageView.isHidden = true
            }
            
            self.relatedLabel.textColor = self.textColorFaint!
            self.titleLabel.textColor = self.textColor!
            self.sourceLabel.textColor = self.textColor!
            self.dateLabel.textColor = self.textColor!
            self.separatorLabel.textColor = self.textColor!
        }
    }
}
