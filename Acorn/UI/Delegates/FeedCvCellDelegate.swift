//
//  FeedCvCellDelegate.swift
//  Acorn
//
//  Created by macOS on 15/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation
import FirebaseUI

protocol FeedCvCellDelegate: class {
    func openArticle(_ articleId: String)
    func openComments(_ articleId: String)
    func openImage(_ urlLink: String?)
    func openShareActivity(_ urlLink: String?, _ article: Article)
    func isUserEmailVerified() -> (Bool)
    func showEmailVerificationAlert(user: User)
    func openOptions(anchor: UIView, post: Article)
    func upvoteActionTapped(article: Article, upvoteButton: UIButton, downvoteButton: UIButton)
    func downvoteActionTapped(article: Article, upvoteButton: UIButton, downvoteButton: UIButton)
    func saveActionTapped(article: Article, saveButton: UIButton)
}
