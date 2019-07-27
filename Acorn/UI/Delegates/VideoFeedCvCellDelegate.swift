//
//  VideoFeedCvCellDelegate.swift
//  Acorn
//
//  Created by macOS on 30/10/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation
import FirebaseUI

protocol VideoFeedCvCellDelegate: class {
    func openVideo(_ video: Video)
    func openComments(_ videoId: String)
    func openShareActivity(_ urlLink: String?, _ video: Video?)
    func isUserEmailVerified() -> (Bool)
    func showEmailVerificationAlert(user: User)
    func openOptions(anchor: UIView, video: Video)
    func upvoteActionTapped(video: Video, upvoteButton: UIButton, downvoteButton: UIButton)
    func downvoteActionTapped(video: Video, upvoteButton: UIButton, downvoteButton: UIButton)
    func saveActionTapped(video: Video, saveButton: UIButton)
}
