//
//  CommentUrlCvCell.swift
//  Acorn
//
//  Created by macOS on 23/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import SDWebImage

class CommentUrlCvCell: UICollectionViewCell {
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    
    @IBOutlet weak var titleWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var sourceWidthConstraint: NSLayoutConstraint!
    
    var comment: Comment?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        view.layer.cornerRadius = 12
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let screenWidth = UIScreen.main.bounds.size.width
        self.titleWidthConstraint.constant = screenWidth * 0.75 - 2 * 16.0 - 88.0
        self.sourceWidthConstraint.constant = screenWidth * 0.75 - 2 * 16.0 - 88.0
    }
    
    func populateCell(_ comment: Comment) {
        imageView.sd_setImage(with: URL(string: comment.imageUrl!), completed: nil)
        titleLabel.text = comment.commentText
        sourceLabel.text = comment.urlSource
    }
}
