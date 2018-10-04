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
    func allThemesButtonTapped()
}

class SubscriptionsHeaderView: UICollectionReusableView {
        
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var allThemesButton: UIView!
    @IBOutlet weak var allThemesCheckbox: Checkbox!
    @IBOutlet weak var allThemesLabel: UILabel!
    weak var delegate: SubscriptionsHeaderViewDelegate?
    
    let nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    lazy var allThemesColor = nightModeOn ? ResourcesNight.ALLTHEMES_COLOR : ResourcesDay.ALLTHEMES_COLOR
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        allThemesCheckbox.tintColor = allThemesColor
        allThemesCheckbox.uncheckedBorderColor = allThemesColor
        allThemesCheckbox.checkedBorderColor = allThemesColor
        allThemesCheckbox.borderWidth = 1
        allThemesCheckbox.borderStyle = .square
        allThemesCheckbox.checkmarkStyle = .square
        allThemesCheckbox.checkmarkColor = allThemesColor
        
        allThemesButton.layer.cornerRadius = 12
        allThemesButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapAllThemesButton)))
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        delegate?.close()
    }
    
    @objc func didTapAllThemesButton() {
        delegate?.allThemesButtonTapped()
    }
    
}
