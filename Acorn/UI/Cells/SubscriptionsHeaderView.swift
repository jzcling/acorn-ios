//
//  SubscriptionsHeaderView.swift
//  Acorn
//
//  Created by macOS on 14/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit

protocol SubscriptionsHeaderViewDelegate: class {
    func close()
    func allThemesButtonTapped(checkbox: Checkbox)
}

class SubscriptionsHeaderView: UICollectionReusableView {
        
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var allThemesButton: UIView!
    @IBOutlet weak var allThemesCheckbox: Checkbox!
    weak var delegate: SubscriptionsHeaderViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        allThemesCheckbox.tintColor = Resources.ALLTHEMES_COLOR
        allThemesCheckbox.uncheckedBorderColor = Resources.ALLTHEMES_COLOR
        allThemesCheckbox.checkedBorderColor = Resources.ALLTHEMES_COLOR
        allThemesCheckbox.borderWidth = 1
        allThemesCheckbox.borderStyle = .square
        allThemesCheckbox.checkmarkStyle = .square
        allThemesCheckbox.checkmarkColor = Resources.ALLTHEMES_COLOR
        
        allThemesButton.layer.cornerRadius = 12
        allThemesButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapAllThemesButton)))
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        print("cancel tapped")
        delegate?.close()
    }
    
    @objc func didTapAllThemesButton() {
        delegate?.allThemesButtonTapped(checkbox: allThemesCheckbox)
    }
    
}
