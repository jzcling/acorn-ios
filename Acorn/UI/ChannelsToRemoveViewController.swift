//
//  ChannelsToRemoveViewController.swift
//  Acorn
//
//  Created by Jeremy Ling on 25/7/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import UIKit
import CoreLocation

class ChannelsToRemoveViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    
    let defaults = UserDefaults.standard
    lazy var nightModeOn = defaults.bool(forKey: "nightModePref")
    var textColor: UIColor?
    
    var channelsRemoved: [String]?
    let dataSource = NetworkDataSource.instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        channelsRemoved = defaults.array(forKey: "videosInFeedChannelsToRemove") as? [String] ?? [String]()
//        print("channelsRemoved: \(channelsRemoved)")
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        let backSwipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(didSwipeBack(_:)))
        backSwipeGesture.edges = .left
        backSwipeGesture.delegate = self
        self.view.addGestureRecognizer(backSwipeGesture)
        
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
        self.tableView.backgroundColor = ResourcesNight.CARD_BG_COLOR
        
        textColor = ResourcesNight.COLOR_DEFAULT_TEXT
    }
    
    func disableNightMode() {
        nightModeOn = false
        self.view.backgroundColor = ResourcesDay.COLOR_BG_MAIN
        self.tableView.backgroundColor = ResourcesDay.CARD_BG_COLOR
        
        textColor = ResourcesDay.COLOR_DEFAULT_TEXT
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
    
    @IBAction func didTapBackButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
        return channelsRemoved!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelTvCell", for: indexPath) as! ChannelTvCell
        let channel = channelsRemoved![indexPath.item]
        cell.channel = channel
        cell.cellTextColor = textColor
        cell.delegate = self
        cell.populateCell()
        return cell
    }
}

extension ChannelsToRemoveViewController: ChannelTvCellDelegate {
    func toggleChannelRemoval(for channel: String, _ bool: Bool) {
        var channelsToRemove = [String]()
        channelsToRemove.append(contentsOf: channelsRemoved!)
        
        if bool {
            if let index = channelsToRemove.firstIndex(of: channel) {
                channelsToRemove.remove(at: index)
                print("\(channel) at \(index) removed: \(channelsToRemove)")
                defaults.set(channelsToRemove, forKey: "videosInFeedChannelsToRemove")
                
                dataSource.setVideosInFeedPreference(for: channel, bool)
            }
        } else {
            channelsToRemove.append(channel)
            defaults.set(channelsToRemove, forKey: "videosInFeedChannelsToRemove")
            
            dataSource.setVideosInFeedPreference(for: channel, bool)
        }
    }
}

extension ChannelsToRemoveViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
