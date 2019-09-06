//
//  DuplicatesCvCell.swift
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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    let dataSource = DataSource.instance
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let inkTouchController = MDCInkTouchController(view: self)
        inkTouchController.addInkView()
        
        self.layer.cornerRadius = 6
    }
    
    override func prepareForReuse() {
        imageView.sd_cancelCurrentImageLoad()
        imageView.isHidden = false
        dataSource.removeArticleObserver(article!.objectID)
    }
    
    func populateCell(articleId: String) {
        dataSource.observeSingleArticle(articleId: articleId) { (article) in
            self.titleLabel.text = article.title
            self.sourceLabel.text = article.source
            self.dateLabel.text = DateUtils.parsePrettyDate(unixTimestamp: -article.pubDate)
            if (article.imageUrl != nil && article.imageUrl != "") {
                imageView.sd_setImage(with: URL(string: article.imageUrl!))
            } else {
                imageView.isHidden = true
            }
        }
    }
}
