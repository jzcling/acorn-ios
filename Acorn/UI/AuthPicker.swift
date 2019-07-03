//
//  AuthPicker.swift
//  Acorn
//
//  Created by macOS on 6/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import FirebaseUI

class AuthPicker: FUIAuthPickerViewController {

    @IBOutlet weak var sloganLabel: UILabel!
    @IBOutlet weak var tncLabel: UILabel!
    @IBOutlet weak var tncPrefixLabel: UILabel!
    
    var nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if nightModeOn {
            enableNightMode()
        } else {
            disableNightMode()
        }
        
        tncLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openTnc)))

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
        sloganLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        tncPrefixLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
    }
    
    func disableNightMode() {
        nightModeOn = false
        self.view.backgroundColor = ResourcesDay.COLOR_BG_MAIN
        sloganLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        tncPrefixLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
    }
    
    @objc func openTnc() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "EULA") as? EULAViewController
        present(vc!, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
