//
//  NotificationsViewController.swift
//  Acorn
//
//  Created by macOS on 25/9/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit

class NotificationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolbar: UIView!
    @IBOutlet weak var clearAllButton: UIButton!
    
    let defaults = UserDefaults.standard
    lazy var nightModeOn = defaults.bool(forKey: "nightModePref")
    lazy var notificationsDict = defaults.dictionary(forKey: "notifications")
//    let notificationsDict = ["a_4998462239652000_6376": "article•4998462239652000_6376•Recommended based on your subscription to Deals•Jewel Coffee: 1-for-1 drinks at over 10 outlets from 3pm onwards daily! Ends 26 Sep 2018•SINGPromos.com•https://cdn.singpromos.com/wp-content/uploads/2018/03/Jewel-Coffee-feat-16-Mar-2018-200x200.jpg•Deals•-1537760348000•-1537760348000", "c_4998462239652000_6376": "comment•4998462239652000_6376•1 new comment on an article you follow•Jewel Coffee: 1-for-1 drinks at over 10 outlets from 3pm onwards daily! Ends 26 Sep 2018•SINGPromos.com•https://cdn.singpromos.com/wp-content/uploads/2018/03/Jewel-Coffee-feat-16-Mar-2018-200x200.jpg•Deals•Deals•-1537760348000"]
    var notificationsArray = [String]()
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defaults.set(notificationsDict, forKey: "notifications")
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 143
        
        if let notificationsDict = notificationsDict {
            for notification in notificationsDict.values {
                notificationsArray.append(notification as! String)
            }
        }

        if nightModeOn {
            nightModeEnabled()
        } else {
            nightModeDisabled()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeEnabled), name: .nightModeOn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeDisabled), name: .nightModeOff, object: nil)
    }
    
    @objc func nightModeEnabled() {
        enableNightMode()
        self.tableView.reloadData()
    }
    
    @objc func nightModeDisabled() {
        disableNightMode()
        self.tableView.reloadData()
    }
    
    func enableNightMode() {
        nightModeOn = true
        self.tableView.backgroundColor = ResourcesNight.COLOR_BG
        self.toolbar.backgroundColor = ResourcesNight.COLOR_BG
        self.clearAllButton.tintColor = ResourcesNight.COLOR_ACCENT
    }
    
    func disableNightMode() {
        nightModeOn = false
        self.tableView.backgroundColor = ResourcesDay.COLOR_BG
        self.toolbar.backgroundColor = ResourcesDay.COLOR_BG
        self.clearAllButton.tintColor = ResourcesDay.COLOR_ACCENT
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notificationsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationTvCell", for: indexPath) as! NotificationTvCell

        cell.notification = notificationsArray[indexPath.row]

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let type = notificationsArray[indexPath.row].components(separatedBy: "•")[0]
        let articleId = notificationsArray[indexPath.row].components(separatedBy: "•")[1]
        if type == "article" {
            openArticle(articleId)
        } else if type == "comment" {
            openComments(articleId)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let type = notificationsArray[indexPath.row].components(separatedBy: "•")[0]
            let articleId = notificationsArray[indexPath.row].components(separatedBy: "•")[1]
            
            var key: String?
            if type == "article" {
                key = "a_\(articleId)"
            } else if type == "comment" {
                key = "c_\(articleId)"
            }
            
            if let key = key {
                notificationsDict?.removeValue(forKey: key)
                notificationsArray.remove(at: indexPath.row)
                defaults.setValue(notificationsDict, forKey: "notifications")
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }

    
    @IBAction func didTapClearAllButton(_ sender: Any) {
        let ac = UIAlertController(title: nil, message: "Are you sure you want to clear all notifications?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        ac.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            self.defaults.removeObject(forKey: "notifications")
            UIApplication.shared.applicationIconBadgeNumber = 0
            self.notificationsDict?.removeAll()
            self.notificationsArray.removeAll()
            self.tableView.reloadData()
        }))
        self.present(ac, animated: true, completion: nil)
    }
}

extension NotificationsViewController: NotificationTvCellDelegate {

    func openArticle(_ articleId: String) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "WebView") as? WebViewViewController
        vc?.articleId = articleId
        self.present(vc!, animated: true, completion: nil)
    }
    
    func openComments(_ articleId: String) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Comment") as? CommentViewController
        vc?.articleId = articleId
        self.present(vc!, animated:true, completion: nil)
    }

    
}
