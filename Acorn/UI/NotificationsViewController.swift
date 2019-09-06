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
    var notificationsArray = [String]()
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    let dataSource = NetworkDataSource.instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 143
        
        if let notifications = notificationsDict {
            var notificationsToRemove = [String]()
            for notification in notifications {
                if let value = notification.value as? String {
                    if (value.components(separatedBy: "|•|").count == 10) {
                        notificationsArray.append(value)
                    } else {
                        notificationsToRemove.append(notification.key)
                    }
                }
            }
            for key in notificationsToRemove {
                self.notificationsDict?.removeValue(forKey: key)
                defaults.setValue(notificationsDict, forKey: "notifications")
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
        self.view.backgroundColor = ResourcesNight.COLOR_BG_MAIN
        self.tableView.backgroundColor = ResourcesNight.COLOR_BG_MAIN
        self.toolbar.backgroundColor = ResourcesNight.COLOR_BG
        self.clearAllButton.tintColor = ResourcesNight.COLOR_ACCENT
    }
    
    func disableNightMode() {
        nightModeOn = false
        self.view.backgroundColor = ResourcesDay.COLOR_BG_MAIN
        self.tableView.backgroundColor = ResourcesDay.COLOR_BG_MAIN
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
        cell.populateCell()

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let type = notificationsArray[indexPath.row].components(separatedBy: "|•|")[0]
        let articleId = notificationsArray[indexPath.row].components(separatedBy: "|•|")[1]
        let mainTheme = notificationsArray[indexPath.row].components(separatedBy: "|•|")[6]
        let link = notificationsArray[indexPath.row].components(separatedBy: "|•|")[9]
        if (type == "article" || type == "deal" || type == "savedArticleReminder" || type == "savedAddressReminder") {
            dataSource.recordOpenArticleDetails(articleId: articleId, mainTheme: mainTheme)
            if link != "" {
                openArticle(articleId)
            } else {
                openComments(articleId)
            }
        } else if type == "comment" {
            openComments(articleId)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let type = notificationsArray[indexPath.row].components(separatedBy: "|•|")[0]
            let articleId = notificationsArray[indexPath.row].components(separatedBy: "|•|")[1]
            
            var key: String?
            if type == "article" {
                key = "a_\(articleId)"
            } else if type == "comment" {
                key = "c_\(articleId)"
            } else if type == "deal" {
                key = "d_\(articleId)"
            } else if type == "savedArticleReminder" {
                key = "s_\(articleId)"
            } else if type == "savedAddressReminder" {
                key = "s_\(articleId)"
            }
            
            if let key = key {
                notificationsDict?.removeValue(forKey: key)
                notificationsArray.remove(at: indexPath.row)
                defaults.setValue(notificationsDict, forKey: "notifications")
                tableView.deleteRows(at: [indexPath], with: .fade)
                UIApplication.shared.applicationIconBadgeNumber = notificationsDict?.count ?? 0
            }
        }
    }

    
    @IBAction func didTapClearAllButton(_ sender: Any) {
        let app = UIApplication.shared
        let ac = UIAlertController(title: nil, message: "Are you sure you want to clear all notifications?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        ac.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            self.defaults.removeObject(forKey: "notifications")
            app.applicationIconBadgeNumber = 0
            self.notificationsDict?.removeAll()
            self.notificationsArray.removeAll()
            self.tableView.reloadData()
        }))
        self.present(ac, animated: true, completion: nil)
    }
}

extension NotificationsViewController: ArticleListTvCellDelegate {

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
