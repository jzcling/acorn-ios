//
//  VideoFeedViewController.swift
//  Acorn
//
//  Created by macOS on 29/10/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import SDWebImage
import Firebase
import FirebaseUI
import MaterialComponents
import Toast_Swift
import PIPKit

class VideoFeedViewController: MDCCollectionViewController {

    var videoList = [Video]() {
        didSet {
            self.collectionView?.reloadData()
        }
    }
    
    lazy var user = Auth.auth().currentUser!
    lazy var uid = user.uid
    
    let dataSource = DataSource.instance
    let loadTrigger: Int = 5
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    let defaults = UserDefaults.standard
    lazy var nightModeOn = defaults.bool(forKey: "nightModePref")
    
    var insets: UIEdgeInsets?
    var cellWidth: CGFloat?
    
    var spinner: UIView?
    
    // colors
    var colorAccent: UIColor?
    var colorPrimary: UIColor?
    var colorBackground: UIColor?
    var colorBackgroundMain: UIColor?
    var colorCardBackground: UIColor?
    var colorCardText: UIColor?
    var colorCardTextFaint: UIColor?
    var colorCardTextRead: UIColor?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let collectionView = collectionView else {
            return
        }
        
        if nightModeOn {
            enableNightMode()
        } else {
            disableNightMode()
        }
        
        self.styler.cellStyle = .card
        self.styler.cellLayoutType = .grid
        self.styler.gridColumnCount = 1
        self.insets = self.collectionView(collectionView,
                                          layout: collectionViewLayout,
                                          insetForSectionAt: 0)
        self.cellWidth = collectionView.bounds.width - (insets?.left)! - (insets?.right)!
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self,
                                 action: #selector(refreshOptions(sender:)),
                                 for: .valueChanged)
        collectionView.refreshControl = refreshControl
        
        let backSwipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(didSwipeBack(_:)))
        backSwipeGesture.edges = .left
        backSwipeGesture.delegate = self
        self.view.addGestureRecognizer(backSwipeGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeEnabled), name: .nightModeOn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeDisabled), name: .nightModeOff, object: nil)
    }
    
    @objc private func nightModeEnabled() {
        enableNightMode()
        self.collectionView?.reloadData()
    }
    
    @objc private func nightModeDisabled() {
        disableNightMode()
        self.collectionView?.reloadData()
    }
    
    func enableNightMode() {
        nightModeOn = true
        colorAccent = ResourcesNight.COLOR_ACCENT
        colorPrimary = ResourcesNight.COLOR_PRIMARY
        colorBackground = ResourcesNight.COLOR_BG
        colorBackgroundMain = ResourcesNight.COLOR_BG_MAIN
        colorCardBackground = ResourcesNight.CARD_BG_COLOR
        colorCardText = ResourcesNight.CARD_TEXT_COLOR
        colorCardTextFaint = ResourcesNight.CARD_TEXT_COLOR_FAINT
        colorCardTextRead = ResourcesNight.CARD_TEXT_COLOR_READ
        
        self.view.backgroundColor = colorBackgroundMain
        self.collectionView?.backgroundColor = colorBackground
    }
    
    func disableNightMode() {
        nightModeOn = false
        colorAccent = ResourcesDay.COLOR_ACCENT
        colorPrimary = ResourcesDay.COLOR_PRIMARY
        colorBackground = ResourcesDay.COLOR_BG
        colorBackgroundMain = ResourcesDay.COLOR_BG_MAIN
        colorCardBackground = ResourcesDay.CARD_BG_COLOR
        colorCardText = ResourcesDay.CARD_TEXT_COLOR
        colorCardTextFaint = ResourcesDay.CARD_TEXT_COLOR_FAINT
        colorCardTextRead = ResourcesDay.CARD_TEXT_COLOR_READ
        
        self.view.backgroundColor = colorBackgroundMain
        self.collectionView?.backgroundColor = colorBackground
    }
    
    @objc private func refreshOptions(sender: UIRefreshControl) {
        resetView()
        getVideoFeed()
        sender.endRefreshing()
    }
    
    private func resetView() {
        dataSource.removeFeedObservers()
        videoList = [Video]()
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        getVideoFeed()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataSource.removeFeedObservers()
        if let spinner = spinner {
            removeSpinner(spinner)
        }
    }
    
    @objc func getVideoFeed() {
        resetView()
        dataSource.getVideoFeed() { (videos) in
            self.videoList = videos
            
            self.collectionView?.reloadData()
            self.collectionViewLayout.invalidateLayout()
            if let spinner = self.spinner { self.removeSpinner(spinner) }
        }
    }
    
    func getMoreVideoFeed(startAt: String) {
        let initialList = self.videoList
        
        dataSource.getVideoFeed(startAt: startAt) { (videos) in
            var combinedList = Array(initialList.dropLast())
            combinedList.append(contentsOf: videos)
            self.videoList = combinedList
            
            self.collectionView?.reloadData()
            self.collectionViewLayout.invalidateLayout()
            if let spinner = self.spinner { self.removeSpinner(spinner) }
        }
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let video = videoList[indexPath.item]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoFeedCvCell", for: indexPath) as! VideoFeedCvCell
        cell.delegate = self
        cell.video = video
        cell.textColor = colorCardText
        cell.textColorFaint = colorCardTextFaint
        cell.textColorRead = colorCardTextRead
        
        cell.backgroundColor = colorCardBackground
        
        cell.sourceLabelWidthConstraint.constant = cellWidth!*7/24
        
        cell.populateCell(video: video)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellHeightAt indexPath: IndexPath) -> CGFloat {
        let video = videoList[indexPath.item]
        
        let cellDefaultHeight: CGFloat = 116
        let imageHeight = self.cellWidth! / 16.0 * 9.0
        
        let tempTitleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.cellWidth! - 24, height: CGFloat.greatestFiniteMagnitude))
        tempTitleLabel.numberOfLines = 0
        tempTitleLabel.lineBreakMode = .byWordWrapping
        tempTitleLabel.font = UIFont.systemFont(ofSize: 18.0)
        tempTitleLabel.text = video.title
        tempTitleLabel.sizeToFit()
        let titleHeight = tempTitleLabel.frame.height
        
        return cellDefaultHeight + titleHeight + imageHeight
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == (self.videoList.count - self.loadTrigger) {
            let lastVideo = videoList.last
            getMoreVideoFeed(startAt: (lastVideo?.trendingIndex)!)
        }
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension VideoFeedViewController: VideoFeedCvCellDelegate {
    
    func openVideo(_ video: Video) {
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterItemID: video.objectID,
            "item_source": video.source ?? "",
            AnalyticsParameterContentType: video.type
        ])
        
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "YTPlayer") as? YTPlayerViewController
        vc?.videoId = video.youtubeVideoId
        PIPKit.show(with: vc!)
    }
    
    func openComments(_ videoId: String) {
//        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Comment") as? CommentViewController
//        vc?.videoId = videoId
//        present(vc!, animated:true, completion: nil)
    }
    
    func openShareActivity(_ urlLink: String?, _ video: Video?) {
        if let shareLink = urlLink {
            let shareText = "Shared using Acorn"
            let shareUrl = URL(string: shareLink)
            let shareItems = [shareText, shareUrl ?? ""] as [Any]
            
            Analytics.logEvent(AnalyticsEventShare, parameters: [
                AnalyticsParameterItemID: video?.objectID ?? "",
                AnalyticsParameterItemCategory: video?.mainTheme ?? "",
                "item_source": video?.source ?? "",
                AnalyticsParameterContentType: video?.type ?? ""
            ])
            
            let activityController = UIActivityViewController(activityItems: shareItems,  applicationActivities: nil)
            DispatchQueue.main.async {
                self.present(activityController, animated: true)
            }
        }
    }
    
    func openOptions(anchor: UIView, video: Video) {
//        let dropdown = DropDown()
//        dropdown.anchorView = anchor
//        dropdown.dataSource = ["Mark as viewed"]
//        dropdown.width = 100
//        dropdown.direction = .bottom
//        dropdown.backgroundColor = nightModeOn ? ResourcesNight.CARD_BG_COLOR : ResourcesDay.CARD_BG_COLOR
//        dropdown.textColor = nightModeOn ? ResourcesNight.CARD_TEXT_COLOR : ResourcesDay.CARD_TEXT_COLOR
//        dropdown.bottomOffset = CGPoint(x: 0, y: (dropdown.anchorView?.plainView.bounds.height)!)
//        dropdown.selectionAction = { (index: Int, item: String) in
//            if item == "Mark as viewed" {
//                self.view.makeToast("Marked as viewed")
//            }
//        }
//        dropdown.show()
    }
    
    func upvoteActionTapped(video: Video, upvoteButton: UIButton, downvoteButton: UIButton) {
        if !isUserEmailVerified() {
            showEmailVerificationAlert(user: self.user)
            return
        }
        
        upvoteButton.isEnabled = false
        downvoteButton.isEnabled = false
        
        var wasUpvoted = false
        var wasDownvoted = false
        
        if let upvoters = video.upvoters {
            if upvoters.keys.contains(self.uid) {
                wasUpvoted = true
            }
        }
        
        if let downvoters = video.downvoters {
            if downvoters.keys.contains(self.uid) {
                wasDownvoted = true
            }
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dataSource.updateVideoVote(video: video, actionIsUpvote: true, wasUpvoted: wasUpvoted, wasDownvoted: wasDownvoted) { dispatchGroup.leave() }
        
        dispatchGroup.enter()
        dataSource.updateUserVote(video: video, actionIsUpvote: true) { (userStatus) in
            if let userStatus = userStatus {
                self.view.makeToast("Congratulations! You have grown into a \(userStatus)")
            }
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            
            upvoteButton.isEnabled = true
            downvoteButton.isEnabled = true
        }
    }
    
    func downvoteActionTapped(video: Video, upvoteButton: UIButton, downvoteButton: UIButton) {
        if !isUserEmailVerified() {
            showEmailVerificationAlert(user: self.user)
            return
        }
        
        upvoteButton.isEnabled = false
        downvoteButton.isEnabled = false
        
        var wasUpvoted = false
        var wasDownvoted = false
        
        if let upvoters = video.upvoters {
            if upvoters.keys.contains(self.uid) {
                wasUpvoted = true
            }
        }
        
        if let downvoters = video.downvoters {
            if downvoters.keys.contains(self.uid) {
                wasDownvoted = true
            }
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dataSource.updateVideoVote(video: video, actionIsUpvote: false, wasUpvoted: wasUpvoted, wasDownvoted: wasDownvoted) { dispatchGroup.leave() }
        
        dispatchGroup.enter()
        dataSource.updateUserVote(video: video, actionIsUpvote: false) { (userStatus) in
            if let userStatus = userStatus {
                self.view.makeToast("Congratulations! You have grown into a \(userStatus)")
            }
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            
            upvoteButton.isEnabled = true
            downvoteButton.isEnabled = true
        }
    }
    
    func saveActionTapped(video: Video, saveButton: UIButton) {
//        saveButton.isEnabled = false
//
//        let dispatchGroup = DispatchGroup()
//        dispatchGroup.enter()
//        dataSource.updateVideoSave(video: video) { dispatchGroup.leave() }
//
//        dispatchGroup.enter()
//        dataSource.updateUserSave(video: video) { dispatchGroup.leave() }
//        dispatchGroup.notify(queue: .main) {
//
//            saveButton.isEnabled = true
//        }
    }
}
