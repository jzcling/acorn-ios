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
    var textColor: UIColor?
    
    weak var delegate: CommentCvCellDelegate?
    
    let nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        view.layer.cornerRadius = 12
    }
    
    func populateCell(_ comment: Comment) {
        imageView.sd_setImage(with: URL(string: comment.imageUrl!), completed: nil)
        titleLabel.text = ""
        titleLabel.text = comment.commentText ?? ""
//        titleLabel.highlightedBackgroundColor = nightModeOn ? ResourcesNight.SEARCH_HIT_BG_COLOR : ResourcesDay.SEARCH_HIT_BG_COLOR
        titleLabel.highlightedTextColor = nightModeOn ? ResourcesNight.SEARCH_HIT_TEXT_COLOR : ResourcesDay.SEARCH_HIT_TEXT_COLOR
        
        sourceLabel.text = ""
        sourceLabel.text = comment.urlSource ?? ""
//        sourceLabel.highlightedBackgroundColor = nightModeOn ? ResourcesNight.SEARCH_HIT_BG_COLOR : ResourcesDay.SEARCH_HIT_BG_COLOR
        sourceLabel.highlightedTextColor = nightModeOn ? ResourcesNight.SEARCH_HIT_TEXT_COLOR : ResourcesDay.SEARCH_HIT_TEXT_COLOR
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openExternalArticle)))
        
        self.view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(openReportAlert)))
    }
    
    override func prepareForReuse() {
        imageView.sd_cancelCurrentImageLoad()
        titleLabel.text = nil
        titleLabel.text = nil
        sourceLabel.text = nil
        sourceLabel.text = nil
        
        super.prepareForReuse()
    }
    
    @objc func openExternalArticle() {
        guard let url = URL(string: comment?.urlLink ?? "") else { return }
        UIApplication.shared.open(url)
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
