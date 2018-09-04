//
//  ActionButtonDelegate.swift
//  Acorn
//
//  Created by macOS on 17/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation

protocol ActionButtonDelegate: class {
    func upvoteArticle(_ article: Article)
    func downvoteArticle(_ article: Article)
    func openComments(_ article: Article)
    func saveArticle(_ article: Article)
    func shareArticle(_ article: Article)
}
