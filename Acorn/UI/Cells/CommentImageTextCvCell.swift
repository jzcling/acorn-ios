//
//  CommentImageTextCvCell.swift
//  Acorn
//
//  Created by macOS on 19/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import SDWebImage
import FirebaseStorage
import InstantSearch
import Lightbox

class CommentImageTextCvCell: UICollectionViewCell {
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var nameDateSeparator: UILabel!
    
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var textWidthConstraint: NSLayoutConstraint!
    
    var comment: Comment?
    var textColor: UIColor?
    var vc: CommentViewController?
    var controller: LightboxController?
    
    weak var delegate: CommentCvCellDelegate?
    
    let nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        view.layer.cornerRadius = 12
    }
    
    func populateCell(_ comment: Comment) {
        if comment.imageUrl!.starts(with: "gs://") {
            let ref = Storage.storage().reference(forURL: comment.imageUrl!)
            imageView.sd_setImage(with: ref, placeholderImage: nil) { (image, error, cacheType, storageRef) in
                self.setUpLightboxController(image: image)
            }
        } else {
            imageView.sd_setImage(with: URL(string: comment.imageUrl!), placeholderImage: nil, options: []) { (image, error, cacheType, url) in
                self.setUpLightboxController(image: image)
            }
        }
        textLabel.text = comment.commentText ?? ""
//            textLabel.highlightedBackgroundColor = nightModeOn ? ResourcesNight.SEARCH_HIT_BG_COLOR : ResourcesDay.SEARCH_HIT_BG_COLOR
        textLabel.highlightedTextColor = nightModeOn ? ResourcesNight.SEARCH_HIT_TEXT_COLOR : ResourcesDay.SEARCH_HIT_TEXT_COLOR
        if nameLabel != nil { nameLabel.text = comment.userDisplayName }
        dateLabel.text = DateUtils.parseCommentDate(unixTimestamp: -comment.pubDate)
        
        if nameLabel != nil { nameLabel.textColor = textColor }
        dateLabel.textColor = textColor
        if nameDateSeparator != nil { nameDateSeparator.textColor = textColor }
        
        self.view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(openReportAlert)))
    }
    
    override func prepareForReuse() {
        textLabel.text = nil
        textLabel.text = nil
        if nameLabel != nil { nameLabel.text = nil }
        dateLabel.text = nil
        imageView.sd_cancelCurrentImageLoad()
        
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
    
    func setUpLightboxController(image: UIImage?) {
        if let image = image {
            let lightboxImage = [LightboxImage(image: image)]
            self.controller = LightboxController(images: lightboxImage)
            
            self.controller!.dynamicBackground = true
            
            self.imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.imageTapped)))
        }
    }
    
    @objc func imageTapped() {
        if let vc = vc, let controller = controller {
            vc.present(controller, animated: true)
        }
    }
    
    @objc func openReportAlert() {
        delegate?.openReportAlert(for: comment!)
    }
}
