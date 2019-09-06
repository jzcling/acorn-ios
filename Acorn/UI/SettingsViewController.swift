//
//  SettingsViewController.swift
//  Acorn
//
//  Created by macOS on 12/9/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import CoreLocation

class SettingsViewController: UIViewController {

    @IBOutlet weak var nightModeSwitch: UISwitch!
    @IBOutlet weak var commentNotifSwitch: UISwitch!
    @IBOutlet weak var recArticlesNotifSwitch: UISwitch!
    @IBOutlet weak var recDealsNotifSwitch: UISwitch!
    @IBOutlet weak var savedArticlesReminderNotifSwitch: UISwitch!
    @IBOutlet weak var locationNotifSwitch: UISwitch!
    @IBOutlet weak var videosInFeedSwitch: UISwitch!
    
    @IBOutlet weak var generalGroupLabel: UILabel!
    @IBOutlet weak var notificationsGroupLabel: UILabel!
    @IBOutlet weak var nightModeLabel: UILabel!
    @IBOutlet weak var commentNotifLabel: UILabel!
    @IBOutlet weak var recArticlesNotifLabel: UILabel!
    @IBOutlet weak var recDealsNotifLabel: UILabel!
    @IBOutlet weak var savedArticlesReminderNotifLabel: UILabel!
    @IBOutlet weak var locationNotifLabel: UILabel!
    @IBOutlet weak var videosInFeedLabel: UILabel!
    @IBOutlet weak var channelsRemovedLabel: UILabel!
    
    
    let defaults = UserDefaults.standard
    lazy var nightModeOn = defaults.bool(forKey: "nightModePref")
    
    let dataSource = NetworkDataSource.instance
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    func registerSettingsBundle() {
        var appDefaults = [String: AnyObject]()
        appDefaults["nightModePref"] = false as AnyObject
        appDefaults["commentNotifPref"] = true as AnyObject
        appDefaults["recArticlesNotifPref"] = true as AnyObject
        appDefaults["recDealsNotifPref"] = true as AnyObject
        appDefaults["savedArticlesReminderNotifPref"] = true as AnyObject
        appDefaults["locationNotifPref"] = true as AnyObject
        appDefaults["videosInFeedPref"] = true as AnyObject
        defaults.register(defaults: appDefaults)
        defaults.synchronize()
    }
    
    func updateDisplayFromDefaults() {
        self.nightModeSwitch.isOn = self.defaults.bool(forKey: "nightModePref")
        self.commentNotifSwitch.isOn = self.defaults.bool(forKey: "commentNotifPref")
        self.recArticlesNotifSwitch.isOn = self.defaults.bool(forKey: "recArticlesNotifPref")
        self.recDealsNotifSwitch.isOn = self.defaults.bool(forKey: "recDealsNotifPref")
        self.savedArticlesReminderNotifSwitch.isOn = self.defaults.bool(forKey: "savedArticlesReminderNotifPref")
        self.locationNotifSwitch.isOn = self.defaults.bool(forKey: "locationNotifPref")
        self.videosInFeedSwitch.isOn = self.defaults.bool(forKey: "videosInFeedPref")
    }
    
    @objc func defaultsChanged() {
        DispatchQueue.main.async {
            self.updateDisplayFromDefaults()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        registerSettingsBundle()
        NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        DispatchQueue.main.async {
            self.updateDisplayFromDefaults()
        }
        
        if nightModeOn {
            enableNightMode()
        } else {
            disableNightMode()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeEnabled), name: .nightModeOn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeDisabled), name: .nightModeOff, object: nil)
        
        let backSwipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(didSwipeBack(_:)))
        backSwipeGesture.edges = .left
        backSwipeGesture.delegate = self
        self.view.addGestureRecognizer(backSwipeGesture)
        
        channelsRemovedLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openChannelsDialog)))
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
    
    @IBAction func toggleRecommendedDealsNotifications(_ sender: UISwitch) {
        defaults.set(sender.isOn, forKey: "recDealsNotifPref")
        dataSource.setRecDealsNotificationPreference(bool: sender.isOn)
    }
    
    @IBAction func toggleSavedArticlesReminderNotifications(_ sender: UISwitch) {
        defaults.set(sender.isOn, forKey: "savedArticlesReminderNotifPref")
        dataSource.setSavedArticlesReminderNotificationPreference(bool: sender.isOn)
    }
    
    @IBAction func toggleLocationNotifications(_ sender: UISwitch) {
        defaults.set(sender.isOn, forKey: "locationNotifPref")
        dataSource.setLocationNotificationPreference(bool: sender.isOn)
        
        let locationManager = CLLocationManager()
        if sender.isOn {
            locationManager.requestAlwaysAuthorization()
        } else {
            for region in locationManager.monitoredRegions {
                locationManager.stopMonitoring(for: region)
                print("stop monitoring: \(region)")
            }
        }
    }
    
    @IBAction func toggleVideosInFeed(_ sender: UISwitch) {
        defaults.set(sender.isOn, forKey: "videosInFeedPref")
        dataSource.setVideosInFeedPreference(sender.isOn)
    }
    
    @objc func openChannelsDialog() {
        guard let vc = mainStoryboard.instantiateViewController(withIdentifier: "Channels To Remove") as? ChannelsToRemoveViewController else { return }
        self.present(vc, animated: true, completion: nil)
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
        recDealsNotifLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        savedArticlesReminderNotifLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        locationNotifLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        videosInFeedLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        channelsRemovedLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
    }
    
    func disableNightMode() {
        nightModeOn = false
        self.view.backgroundColor = ResourcesDay.COLOR_BG_MAIN
        generalGroupLabel.textColor = ResourcesDay.COLOR_ACCENT
        notificationsGroupLabel.textColor = ResourcesDay.COLOR_ACCENT
        nightModeLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        commentNotifLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        recArticlesNotifLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        recDealsNotifLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        savedArticlesReminderNotifLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        locationNotifLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        videosInFeedLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        channelsRemovedLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
    }
    
    @objc func didSwipeBack(_ sender: UIScreenEdgePanGestureRecognizer) {
        let dX = sender.translation(in: self.view).x
        if sender.state == .ended {
            let fraction = abs(dX/self.view.bounds.width)
            if fraction > 0.3 {
                dismiss(animated: true, completion: nil)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension SettingsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
