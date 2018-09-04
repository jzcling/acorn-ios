//
//  SubscriptionsFooterView.swift
//  Acorn
//
//  Created by macOS on 14/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit

protocol SubscriptionsFooterViewDelegate: class {
    func saveThemes()
}

class SubscriptionsFooterView: UICollectionReusableView {
 
    @IBOutlet weak var saveButton: UIButton!
    weak var delegate: SubscriptionsFooterViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        saveButton.layer.cornerRadius = 15
    }
    
    @IBAction func didTapSave(_ sender: Any) {
        delegate?.saveThemes()
    }
}
