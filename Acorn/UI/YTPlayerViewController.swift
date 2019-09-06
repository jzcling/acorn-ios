//
//  YTPlayerViewController.swift
//  Acorn
//
//  Created by macOS on 30/10/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import YoutubePlayer_in_WKWebView
import PIPKit
import Firebase
import FirebaseUI

class YTPlayerViewController: UIViewController, PIPUsable {

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var fullscreenButton: UIButton!
    @IBOutlet weak var pipButton: UIButton!
    @IBOutlet weak var player: WKYTPlayerView!
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var upvoteButton: BounceButton!
    @IBOutlet weak var downvoteButton: BounceButton!
    @IBOutlet weak var commentButton: BounceButton!
    @IBOutlet weak var saveButton: BounceButton!
    @IBOutlet weak var shareButton: BounceButton!
    
    lazy var user = Auth.auth().currentUser!
    lazy var uid = user.uid
    
    let dataSource = NetworkDataSource.instance
    var video: Video?
    
//    var player: YTSwiftyPlayer!
    var videoId: String?
    var id: String?
    
    var initialState: PIPState { return .full }
    var initialPosition: PIPPosition { return .bottomRight }
    var pipSize: CGSize = CGSize(width: 288.0, height: 162.0)
    
    var defaultTint: UIColor?
    var upvoteTint: UIColor?
    var downvoteTint: UIColor?
    var commentTint: UIColor?
    var saveTint: UIColor?
    var shareTint: UIColor?
    
    let timeLog = TimeLog()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("videoId: \(videoId!)")
//        videoPlayer = YTSwiftyPlayer(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height), playerVars: [.videoID(videoId!), .playsInline(true)])
//        videoPlayer.autoplay = true
//        view = videoPlayer
//        videoPlayer.delegate = self
//        videoPlayer.loadPlayer()
        player.load(withVideoId: videoId!)
        
        view.bringSubviewToFront(cancelButton)
        
        let backSwipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(didSwipeBack(_:)))
        backSwipeGesture.edges = .left
        backSwipeGesture.delegate = self
        self.view.addGestureRecognizer(backSwipeGesture)
        
        let downSwipeGesture = UIPanGestureRecognizer(target: self, action: #selector(didSwipeDown(_:)))
        downSwipeGesture.delegate = self
        self.view.addGestureRecognizer(downSwipeGesture)
        
        defaultTint = ResourcesNight.BUTTON_DEFAULT_TINT_COLOR
        upvoteTint = ResourcesNight.UPVOTE_TINT_COLOR
        downvoteTint = ResourcesNight.DOWNVOTE_TINT_COLOR
        commentTint = ResourcesNight.COMMENT_TINT_COLOR
        saveTint = ResourcesNight.SAVE_TINT_COLOR
        shareTint = ResourcesNight.SHARE_TINT_COLOR
        
        if let videoId = videoId {
            id = "yt:\(videoId)"
            getVideo(id: id!)
        }
        
        timeLog.userId = uid
        timeLog.itemId = id
        timeLog.type = "video"
        timeLog.openTime = Date().timeIntervalSince1970 * 1000
    }

    @objc func didSwipeBack(_ sender: UIScreenEdgePanGestureRecognizer) {
        let dX = sender.translation(in: self.view).x
        if sender.state == .ended {
            let fraction = abs(dX/self.view.bounds.width)
            if fraction > 0.3 {
                PIPKit.dismiss(animated: true)
            }
        }
    }
    
    @objc func didSwipeDown(_ sender: UIScreenEdgePanGestureRecognizer) {
        let dY = sender.translation(in: self.view).y
        if sender.state == .ended {
            let fraction = abs(dY/self.view.bounds.height)
            if fraction > 0.3 {
                startPIPMode()
            }
        }
    }
    
    func getVideo(id: String) {
        dataSource.getSingleVideo(id: id) { (video) in
            self.video = video
            if let upvoters = video.upvoters {
                if upvoters.keys.contains(self.uid) { self.upvoteButton.tintColor = self.upvoteTint }
            }
            if let downvoters = video.downvoters {
                if downvoters.keys.contains(self.uid) { self.downvoteButton.tintColor = self.downvoteTint }
            }
            if let commenters = video.commenters {
                if commenters.keys.contains(self.uid) { self.commentButton.tintColor = self.commentTint }
            }
            if let savers = video.savers {
                if savers.keys.contains(self.uid) { self.saveButton.tintColor = self.saveTint }
            }
            
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterItemID: video.objectID,
                AnalyticsParameterItemCategory: video.mainTheme ?? "",
                "item_source": video.source ?? "",
                AnalyticsParameterContentType: video.type
                ])
        }
    }
    
    @IBAction func didTapCancelButton(_ sender: Any) {
        PIPKit.dismiss(animated: true)
    }
    
    @IBAction func didTapFullscreenButton(_ sender: Any) {
        stopPIPMode()
    }
    
    @IBAction func didTapPipButton(_ sender: Any) {
        startPIPMode()
    }
    
    func didChangedState(_ state: PIPState) {
        switch state {
        case .pip:
            fullscreenButton.isHidden = false
            cancelButton.isHidden = false
            pipButton.isHidden = true
            buttonStackView.isHidden = true
        case .full:
            fullscreenButton.isHidden = true
            cancelButton.isHidden = true
            pipButton.isHidden = false
        }
    }
    
    @IBAction func didTapUpvoteButton(_ sender: Any) {
        upvoteActionTapped(video: self.video!, upvoteButton: upvoteButton, downvoteButton: downvoteButton)
    }
    
    @IBAction func didTapDownvoteButton(_ sender: Any) {
        downvoteActionTapped(video: self.video!, upvoteButton: upvoteButton, downvoteButton: downvoteButton)
    }
    
    @IBAction func didTapCommentButton(_ sender: Any) {
    }
    
    @IBAction func didTapSaveButton(_ sender: Any) {
    }
    
    @IBAction func didTapShareButton(_ sender: Any) {
        guard let video = self.video else { return }
        let url = ShareUtils.createVideoShareUri(videoId: video.objectID, sharerId: uid)
        ShareUtils.createShortDynamicLink(url: url, sharerId: uid) { (dynamicLink) in
            self.openShareActivity(dynamicLink, video)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("viewDidDisappear")
        let now = Date().timeIntervalSince1970 * 1000
        timeLog.activeTime = now - timeLog.openTime!
        timeLog.closeTime = now
        self.dataSource.logItemTimeLog(timeLog)
        super.viewDidDisappear(true)
    }
}

//extension YTPlayerViewController: YTSwiftyPlayerDelegate {
//    func player(_ player: YTSwiftyPlayer, didChangeState state: YTSwiftyPlayerState) {
//        print(state)
//    }
//    
//    func player(_ player: YTSwiftyPlayer, didChangeQuality quality: YTSwiftyVideoQuality) {
//        print(quality)
//    }
//    
//    func player(_ player: YTSwiftyPlayer, didReceiveError error: YTSwiftyPlayerError) {
//        print(error)
//    }
//    
//    func player(_ player: YTSwiftyPlayer, didUpdateCurrentTime currentTime: Double) {
//        print(currentTime)
//    }
//    
//    func player(_ player: YTSwiftyPlayer, didChangePlaybackRate playbackRate: Double) {
//        print(playbackRate)
//    }
//    
//    func playerReady(_ player: YTSwiftyPlayer) {
//        print("playerReady")
//    }
//    
//    func apiDidChange(_ player: YTSwiftyPlayer) {
//        print("apiDidChange")
//    }
//    
//    func youtubeIframeAPIReady(_ player: YTSwiftyPlayer) {
//        print("iframeApiReady")
//    }
//    
//    func youtubeIframeAPIFailedToLoad(_ player: YTSwiftyPlayer) {
//        print("iframeApiFailed")
//    }
//    
//    
//}

extension YTPlayerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension YTPlayerViewController: VideoFeedCvCellDelegate {
    
    func openVideo(_ video: Video) {}
    
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
    
    func openOptions(anchor: UIView, video: Video) {}
    
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
        dataSource.updateVideoVote(video: video, actionIsUpvote: true, wasUpvoted: wasUpvoted, wasDownvoted: wasDownvoted) {
            self.downvoteButton.tintColor = self.defaultTint
            self.upvoteButton.tintColor = wasUpvoted ? self.defaultTint : self.upvoteTint
            dispatchGroup.leave()
        }
        
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
        dataSource.updateVideoVote(video: video, actionIsUpvote: false, wasUpvoted: wasUpvoted, wasDownvoted: wasDownvoted) {
            self.upvoteButton.tintColor = self.defaultTint
            self.downvoteButton.tintColor = wasDownvoted ? self.defaultTint : self.downvoteTint
            dispatchGroup.leave()
        }
        
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
