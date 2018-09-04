//
//  SubscriptionCvCell.swift
//  Acorn
//
//  Created by macOS on 10/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit

class SubscriptionCvCell: UICollectionViewCell {
    
    @IBOutlet weak var checkbox: Checkbox!
    @IBOutlet weak var theme: UILabel!
    
    var object: Theme? {
        willSet {
        }
        didSet {
//            print("didSet: name: \(String(describing: object?.name)), isSelected: \(String(describing: object?.isSelected))")
            DispatchQueue.main.async {
                self.checkbox.isChecked = (self.object?.isSelected)!
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 12
        
        checkbox.borderWidth = 1
        checkbox.borderStyle = .square
        checkbox.checkmarkStyle = .square
        
//        self.contentView.translatesAutoresizingMaskIntoConstraints = false
//        theme.preferredMaxLayoutWidth = self.bounds.width - 54 - checkbox.frame.width
        
    }
    
//    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
//            setNeedsLayout()
//            layoutIfNeeded()
//            let size = contentView.systemLayoutSizeFitting(layoutAttributes.size)
//            var frame = layoutAttributes.frame
//            frame.size.height = ceil(size.height)
//            layoutAttributes.frame = frame
//            return layoutAttributes
//        }
}
