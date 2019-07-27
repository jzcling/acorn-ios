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

class YTPlayerViewController: UIViewController, PIPUsable {

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var fullscreenButton: UIButton!
    @IBOutlet weak var pipButton: UIButton!
    @IBOutlet weak var player: WKYTPlayerView!
    
//    var player: YTSwiftyPlayer!
    var videoId: String?
    
    var initialState: PIPState { return .full }
    var initialPosition: PIPPosition { return .bottomRight }
    var pipSize: CGSize = CGSize(width: 288.0, height: 162.0)
    
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
    
    @objc func didSwipeDown(_ sender: UIScreenEdgePanGestureRecognizer) {
        let dY = sender.translation(in: self.view).y
        if sender.state == .ended {
            let fraction = abs(dY/self.view.bounds.height)
            if fraction > 0.3 {
                startPIPMode()
            }
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
        case .full:
            fullscreenButton.isHidden = true
            cancelButton.isHidden = true
            pipButton.isHidden = false
        }
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
