//
//  CommentTextCvCell.swift
//  Acorn
//
//  Created by macOS on 19/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import InstantSearch

class CommentTextCvCell: UICollectionViewCell {
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var nameDateSeparator: UILabel!
    
    @IBOutlet weak var textWidthConstraint: NSLayoutConstraint!
    
    var comment: Comment?
    var textColor: UIColor?
    
    weak var delegate: CommentCvCellDelegate?
    
    let nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        view.layer.cornerRadius = 12
    }
    
    func populateCell(_ comment: Comment) {
        textLabel.text = comment.commentText ?? ""
//        textLabel.highlightedBackgroundColor = nightModeOn ? ResourcesNight.SEARCH_HIT_BG_COLOR : ResourcesDay.SEARCH_HIT_BG_COLOR
        textLabel.highlightedTextColor = nightModeOn ? ResourcesNight.SEARCH_HIT_TEXT_COLOR : ResourcesDay.SEARCH_HIT_TEXT_COLOR
        if nameLabel != nil { nameLabel.text = comment.userDisplayName }
        dateLabel.text = DateUtils.parseCommentDate(unixTimestamp: -comment.pubDate)
        
        if nameLabel != nil { nameLabel.textColor = textColor }
        dateLabel.textColor = textColor
        if nameDateSeparator != nil { nameDateSeparator.textColor = textColor }
        
        self.view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(openReportAlert)))
    }
    
    func populateReportedCell(_ comment: Comment) {
        textLabel.text = "Comment reported for inappropriate content"
        textLabel.textColor = .lightGray
        if nameLabel != nil { nameLabel.text = comment.userDisplayName }
        dateLabel.text = DateUtils.parseCommentDate(unixTimestamp: -comment.pubDate)
        
        if nameLabel != nil { nameLabel.textColor = textColor }
        dateLabel.textColor = textColor
        if nameDateSeparator != nil { nameDateSeparator.textColor = textColor }
    }
    
    override func prepareForReuse() {
        textLabel.text = nil
        textLabel.text = nil
        textLabel.textColor = nightModeOn ? ResourcesNight.COLOR_DEFAULT_TEXT : ResourcesDay.COLOR_DEFAULT_TEXT
        if nameLabel != nil { nameLabel.text = nil }
        dateLabel.text = nil
        
        super.prepareForReuse()
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: 0)
        let size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.defaultLow)
        
        let frame = CGRect(origin: attributes.frame.origin, size: size)
        attributes.frame = frame
        return attributes
    }
    
    @objc func openReportAlert() {
        delegate?.openReportAlert(for: comment!)
    }
}
