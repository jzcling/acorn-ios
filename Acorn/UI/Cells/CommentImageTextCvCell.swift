//
//  CommentImageTextCvCell.swift
//  Acorn
//
//  Created by macOS on 19/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import SDWebImage

class CommentImageTextCvCell: UICollectionViewCell {
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var textWidthConstraint: NSLayoutConstraint!
    
    var comment: Comment?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        view.layer.cornerRadius = 12
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let screenWidth = UIScreen.main.bounds.size.width
        self.imageWidthConstraint.constant = screenWidth * 0.75 - 2 * 8.0
        self.textWidthConstraint.constant = screenWidth * 0.75 - 2 * 8.0
    }
    
    func populateCell(_ comment: Comment) {
        imageView.sd_setImage(with: URL(string: comment.imageUrl!), completed: nil)
        textLabel.text = comment.commentText
        if nameLabel != nil { nameLabel.text = comment.userDisplayName }
        dateLabel.text = DateUtils.parseCommentDate(unixTimestamp: -comment.pubDate)
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
}
