//
//  EULAViewController.swift
//  Acorn
//
//  Created by macOS on 3/10/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit

class EULAViewController: UIViewController {
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var eulaTextView: UITextView!
    
    var nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if nightModeOn {
            enableNightMode()
        } else {
            disableNightMode()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeEnabled), name: .nightModeOn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeDisabled), name: .nightModeOff, object: nil)
    }
    
    @objc private func nightModeEnabled() {
        enableNightMode()
    }
    
    @objc private func nightModeDisabled() {
        disableNightMode()
    }
    
    func enableNightMode() {
        nightModeOn = true
        self.view.backgroundColor = ResourcesNight.COLOR_BG_MAIN
        eulaTextView.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
    }
    
    func disableNightMode() {
        nightModeOn = false
        self.view.backgroundColor = ResourcesDay.COLOR_BG_MAIN
        eulaTextView.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        eulaTextView.setContentOffset(.zero, animated: false)
    }

    @IBAction func didTapBackButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
