//
//  Article.swift
//  Acorn
//
//  Created by macOS on 5/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation
import FirebaseUI
import Firebase

class Article {
    var entityId: Int?
    var objectID: String
    var type: String
    var postAuthorUid: String?
    var postAuthor: String?
    var postText: String?
    var postImageUrl: String?
    var postDate: Double?
    var title: String?
    var source: String?
    var pubDate: Double
    var imageUrl: String?
    var link: String?
    var author: String?
    var mainTheme: String?
    var readTime: Int?
    var trendingIndex: String?
    var voteCount: Int? = 0
    var commentCount: Int? = 0
    var saveCount: Int? = 0
    var shareCount: Int? = 0
    var openCount: Int? = 0
    var category: [String]? = [String]()
    var theme: [String]? = [String]()
    var upvoters: [String: Double]? = [String: Double]()
    var downvoters: [String: Double]? = [String: Double]()
    var commenters: [String: Int]? = [String: Int]()
    var savers: [String: Double]? = [String: Double]()
    var sharers: [String: Double]? = [String: Double]()
    var openedBy: [String: Double]? = [String: Double]()
    var notificationTokens: [String: String]? = [String: String]()
    var changedSinceLastJob: Bool? = true
    var isReported: Bool? = false
    var htmlContent: String? = nil
    var reminderDate: Double?
    var selector: String?
    var hasAddress: Bool? = false
    var duplicates: [String: Double]? = [String: Double]()
    var seenBy: [String: Double]? = [String: Double]()
    var postcode: [String]? = [String]()
    
    init(snapshot: DataSnapshot) {
        let value = snapshot.value as? [String: Any]
        self.entityId = value?["entityId"] as? Int
        self.objectID = value?["objectID"] as? String ?? ""
        self.type = value?["type"] as? String ?? ""
        self.postAuthorUid = value?["postAuthorUid"] as? String
        self.postAuthor = value?["postAuthor"] as? String
        self.postText = value?["postText"] as? String
        self.postImageUrl = value?["postImageUrl"] as? String
        self.postDate = value?["postDate"] as? Double
        self.title = value?["title"] as? String
        self.source = value?["source"] as? String
        self.pubDate = value?["pubDate"] as? Double ?? -(Date().timeIntervalSince1970 * 1000)
        self.imageUrl = value?["imageUrl"] as? String
        self.link = value?["link"] as? String
        self.author = value?["author"] as? String
        self.mainTheme = value?["mainTheme"] as? String
        self.readTime = value?["readTime"] as? Int
        self.trendingIndex = value?["trendingIndex"] as? String
        self.voteCount = value?["voteCount"] as? Int ?? 0
        self.commentCount = value?["commentCount"] as? Int ?? 0
        self.saveCount = value?["saveCount"] as? Int ?? 0
        self.shareCount = value?["shareCount"] as? Int ?? 0
        self.openCount = value?["openCount"] as? Int ?? 0
        self.category = value?["category"] as? [String] ?? [String]()
        self.theme = value?["theme"] as? [String] ?? [String] ()
        self.upvoters = value?["upvoters"] as? [String: Double] ?? [String: Double]()
        self.downvoters = value?["downvoters"] as? [String: Double] ?? [String: Double]()
        self.commenters = value?["commenters"] as? [String: Int] ?? [String: Int]()
        self.savers = value?["savers"] as? [String: Double] ?? [String: Double]()
        self.sharers = value?["sharers"] as? [String: Double] ?? [String: Double]()
        self.openedBy = value?["openedBy"] as? [String: Double] ?? [String: Double]()
        self.notificationTokens = value?["notificationTokens"] as? [String: String] ?? [String: String]()
        self.changedSinceLastJob = value?["changedSinceLastJob"] as? Bool ?? true
        self.isReported = value?["isReported"] as? Bool ?? false
        self.htmlContent = value?["htmlContent"] as? String
        self.reminderDate = value?["reminderDate"] as? Double
        self.selector = value?["selector"] as? String
        self.hasAddress = value?["hasAddress"] as? Bool ?? false
        self.duplicates = value?["duplicates"] as? [String: Double] ?? [String: Double]()
        self.seenBy = value?["seenBy"] as? [String: Double] ?? [String: Double]()
    }
    
    init(json: [String: Any]) {
        let value = json
        self.entityId = value["entityId"] as? Int
        self.objectID = value["objectID"] as! String
        self.type = value["type"] as! String
        self.postAuthorUid = value["postAuthorUid"] as? String
        self.postAuthor = value["postAuthor"] as? String
        self.postText = value["postText"] as? String
        let postImageUrl = value["postImageUrl"] as? String
        self.postImageUrl = postImageUrl
        self.postDate = value["postDate"] as? Double
        self.title = value["title"] as? String
        self.source = value["source"] as? String
        self.pubDate = value["pubDate"] as! Double
        let imageUrl = value["imageUrl"] as? String
        self.imageUrl = imageUrl
        let link = value["link"] as? String
        self.link = link
        self.author = value["author"] as? String
        self.mainTheme = value["mainTheme"] as? String
        self.readTime = value["readTime"] as? Int
        self.trendingIndex = value["trendingIndex"] as? String
        self.voteCount = value["voteCount"] as? Int ?? 0
        self.commentCount = value["commentCount"] as? Int ?? 0
        self.saveCount = value["saveCount"] as? Int ?? 0
        self.shareCount = value["shareCount"] as? Int ?? 0
        self.openCount = value["openCount"] as? Int ?? 0
        self.category = value["category"] as? [String] ?? [String]()
        self.theme = value["theme"] as? [String] ?? [String]()
        self.upvoters = value["upvoters"] as? [String: Double] ?? [String: Double]()
        self.downvoters = value["downvoters"] as? [String: Double] ?? [String: Double]()
        self.commenters = value["commenters"] as? [String: Int] ?? [String: Int]()
        self.savers = value["savers"] as? [String: Double] ?? [String: Double]()
        self.sharers = value["sharers"] as? [String: Double] ?? [String: Double]()
        self.openedBy = value["openedBy"] as? [String: Double] ?? [String: Double]()
        self.notificationTokens = value["notificationTokens"] as? [String: String] ?? [String: String]()
        self.changedSinceLastJob = value["changedSinceLastJob"] as? Bool ?? true
        self.isReported = value["isReported"] as? Bool ?? false
        self.htmlContent = value["htmlContent"] as? String
        self.reminderDate = value["reminderDate"] as? Double
        self.selector = value["selector"] as? String
        self.hasAddress = value["hasAddress"] as? Bool ?? false
        self.duplicates = value["duplicates"] as? [String: Double] ?? [String: Double]()
        self.seenBy = value["seenBy"] as? [String: Double] ?? [String: Double]()
    }
    
    init(video: Video) {
        self.objectID = video.objectID
        self.type = video.type
        self.postAuthorUid = video.postAuthorUid
        self.postAuthor = video.postAuthor
        self.postText = video.postText
        self.link = video.videoUrl != nil ? video.videoUrl : video.postVideoUrl
        self.postDate = video.postDate
        self.title = video.title
        self.source = video.source
        self.pubDate = video.pubDate
        self.author = video.author
        self.mainTheme = video.mainTheme
        self.trendingIndex = video.trendingIndex
        self.voteCount = video.voteCount
        self.commentCount = video.commentCount
        self.saveCount = video.saveCount
        self.shareCount = video.shareCount
        self.openCount = video.viewCount
        self.category = video.category
        self.theme = video.theme
        self.upvoters = video.upvoters
        self.downvoters = video.downvoters
        self.commenters = video.commenters
        self.savers = video.savers
        self.sharers = video.sharers
        self.openedBy = video.viewedBy
        self.notificationTokens = video.notificationTokens
        self.changedSinceLastJob = video.changedSinceLastJob
        self.isReported = video.isReported
        self.readTime = Int(video.youtubeViewCount ?? 0)
        self.seenBy = video.seenBy
    }
}
