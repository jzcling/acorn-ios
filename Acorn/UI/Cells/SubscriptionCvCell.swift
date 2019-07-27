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
    @IBOutlet weak var themeLabel: UILabel!
    
    var object: Theme?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 12
        
        checkbox.borderWidth = 1
        checkbox.borderStyle = .square
        checkbox.checkmarkStyle = .square
    }
}
