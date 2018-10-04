//
//  SettingsViewController.swift
//  Acorn
//
//  Created by macOS on 12/9/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var nightModeSwitch: UISwitch!
    @IBOutlet weak var commentNotifSwitch: UISwitch!
    @IBOutlet weak var recArticlesNotifSwitch: UISwitch!
    
    @IBOutlet weak var generalGroupLabel: UILabel!
    @IBOutlet weak var notificationsGroupLabel: UILabel!
    @IBOutlet weak var nightModeLabel: UILabel!
    @IBOutlet weak var commentNotifLabel: UILabel!
    @IBOutlet weak var recArticlesNotifLabel: UILabel!
    
    let defaults = UserDefaults.standard
    lazy var nightModeOn = defaults.bool(forKey: "nightModePref")
    
    let dataSource = DataSource.instance
    
    func registerSettingsBundle() {
        let appDefaults = [String: AnyObject]()
        defaults.register(defaults: appDefaults)
    }
    
    func updateDisplayFromDefaults() {
        DispatchQueue.main.async {
            self.nightModeSwitch.isOn = self.defaults.bool(forKey: "nightModePref")
            self.commentNotifSwitch.isOn = self.defaults.bool(forKey: "commentNotifPref")
            self.recArticlesNotifSwitch.isOn = self.defaults.bool(forKey: "recArticlesNotifPref")
        }
    }
    
    @objc func defaultsChanged() {
        updateDisplayFromDefaults()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        registerSettingsBundle()
        updateDisplayFromDefaults()
        
        if nightModeOn {
            enableNightMode()
        } else {
            disableNightMode()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeEnabled), name: .nightModeOn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeDisabled), name: .nightModeOff, object: nil)
    }
    
    @IBAction func toggleNightMode(_ sender: UISwitch) {
        defaults.set(sender.isOn, forKey: "nightModePref")
        
        NotificationCenter.default.post(name: sender.isOn ? .nightModeOn : .nightModeOff, object: nil)
    }
    
    @IBAction func toggleCommentNotifications(_ sender: UISwitch) {
        defaults.set(sender.isOn, forKey: "commentNotifPref")
        dataSource.setCommentsNotificationPreference(bool: sender.isOn)
    }
    
    @IBAction func toggleRecommendedArticlesNotifications(_ sender: UISwitch) {
        defaults.set(sender.isOn, forKey: "recArticlesNotifPref")
        dataSource.setRecArticlesNotificationPreference(bool: sender.isOn)
    }
    
    @objc func nightModeEnabled() {
        enableNightMode()
    }
    
    @objc func nightModeDisabled() {
        disableNightMode()
    }

    func enableNightMode() {
        nightModeOn = true
        self.view.backgroundColor = ResourcesNight.COLOR_BG_MAIN
        generalGroupLabel.textColor = ResourcesNight.COLOR_ACCENT
        notificationsGroupLabel.textColor = ResourcesNight.COLOR_ACCENT
        nightModeLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        commentNotifLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        recArticlesNotifLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
    }
    
    func disableNightMode() {
        nightModeOn = false
        self.view.backgroundColor = ResourcesDay.COLOR_BG_MAIN
        generalGroupLabel.textColor = ResourcesDay.COLOR_ACCENT
        notificationsGroupLabel.textColor = ResourcesDay.COLOR_ACCENT
        nightModeLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        commentNotifLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        recArticlesNotifLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
