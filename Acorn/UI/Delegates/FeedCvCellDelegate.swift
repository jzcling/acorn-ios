//
//  FeedCvCellDelegate.swift
//  Acorn
//
//  Created by macOS on 15/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation

protocol FeedCvCellDelegate: class {
    func openArticle(_ cell: FeedCvCell)
    func openArticle(_ cell: FeedCvCellNoImage)
    func openArticle(_ cell: FeedCvCellPostWithArticle)
    func openArticle(_ cell: FeedCvCellSaved)
    func openComments(_ cell: FeedCvCell)
    func openComments(_ cell: FeedCvCellNoImage)
    func openComments(_ cell: FeedCvCellPost)
    func openComments(_ cell: FeedCvCellPostNoImage)
    func openComments(_ cell: FeedCvCellPostWithArticle)
    func openComments(_ cell: FeedCvCellSaved)
    func openImage(_ cell: FeedCvCellPost)
    func openShareActivity(_ cell: FeedCvCell)
    func openShareActivity(_ cell: FeedCvCellNoImage)
    func openShareActivity(_ cell: FeedCvCellPostWithArticle)
}
