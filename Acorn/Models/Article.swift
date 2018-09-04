//
//  Article.swift
//  Acorn
//
//  Created by macOS on 5/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation
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
    var voteCount: Int?
    var commentCount: Int?
    var saveCount: Int?
    var shareCount: Int?
    var category: [String]?
    var theme: [String]?
    var upvoters: [String: Double]?
    var downvoters: [String: Double]?
    var commenters: [String: Int]?
    var savers: [String: Double]?
    var sharers: [String: Double]?
    var notificationTokens: [String: String]?
    var changedSinceLastJob: Bool?
    
    init(snapshot: DataSnapshot) {
        let value = snapshot.value as! [String: Any]
        self.entityId = value["entityId"] as? Int
        self.objectID = value["objectID"] as! String
        self.type = value["type"] as! String
        self.postAuthorUid = value["postAuthorUid"] as? String
        self.postAuthor = value["postAuthor"] as? String
        self.postText = value["postText"] as? String
        var postImageUrl = value["postImageUrl"] as? String
//        if let httpRange = postImageUrl?.range(of: "http:") {
//            postImageUrl?.replaceSubrange(httpRange, with: "https:")
//        }
        self.postImageUrl = postImageUrl
        self.postDate = value["postDate"] as? Double
        self.title = value["title"] as? String
        self.source = value["source"] as? String
        self.pubDate = value["pubDate"] as! Double
        var imageUrl = value["imageUrl"] as? String
//        if let httpRange = imageUrl?.range(of: "http:") {
//            imageUrl?.replaceSubrange(httpRange, with: "https:")
//        }
        self.imageUrl = imageUrl
        var link = value["link"] as? String
//        if let httpRange = link?.range(of: "http:") {
//            link?.replaceSubrange(httpRange, with: "https:")
//        }
        self.link = link
        self.author = value["author"] as? String
        self.mainTheme = value["mainTheme"] as? String
        self.readTime = value["readTime"] as? Int
        self.trendingIndex = value["trendingIndex"] as? String
        self.voteCount = value["voteCount"] as? Int
        self.commentCount = value["commentCount"] as? Int
        self.saveCount = value["saveCount"] as? Int
        self.shareCount = value["shareCount"] as? Int
        self.category = value["category"] as? [String]
        self.theme = value["theme"] as? [String]
        self.upvoters = value["upvoters"] as? [String: Double]
        self.downvoters = value["downvoters"] as? [String: Double]
        self.commenters = value["commenters"] as? [String: Int]
        self.savers = value["savers"] as? [String: Double]
        self.sharers = value["sharers"] as? [String: Double]
        self.notificationTokens = value["notificationTokens"] as? [String: String]
        self.changedSinceLastJob = value["changedSinceLastJob"] as? Bool
    }
    
    init(json: [String: Any]) {
        let value = json
        self.entityId = value["entityId"] as? Int
        self.objectID = value["objectID"] as! String
        self.type = value["type"] as! String
        self.postAuthorUid = value["postAuthorUid"] as? String
        self.postAuthor = value["postAuthor"] as? String
        self.postText = value["postText"] as? String
        var postImageUrl = value["postImageUrl"] as? String
//        if let httpRange = postImageUrl?.range(of: "http:") {
//            postImageUrl?.replaceSubrange(httpRange, with: "https:")
//        }
        self.postImageUrl = postImageUrl
        self.postDate = value["postDate"] as? Double
        self.title = value["title"] as? String
        self.source = value["source"] as? String
        self.pubDate = value["pubDate"] as! Double
        var imageUrl = value["imageUrl"] as? String
//        if let httpRange = imageUrl?.range(of: "http:") {
//            imageUrl?.replaceSubrange(httpRange, with: "https:")
//        }
        self.imageUrl = imageUrl
        var link = value["link"] as? String
//        if let httpRange = link?.range(of: "http:") {
//            link?.replaceSubrange(httpRange, with: "https:")
//        }
        self.link = link
        self.author = value["author"] as? String
        self.mainTheme = value["mainTheme"] as? String
        self.readTime = value["readTime"] as? Int
        self.trendingIndex = value["trendingIndex"] as? String
        self.voteCount = value["voteCount"] as? Int
        self.commentCount = value["commentCount"] as? Int
        self.saveCount = value["saveCount"] as? Int
        self.shareCount = value["shareCount"] as? Int
        self.category = value["category"] as? [String]
        self.theme = value["theme"] as? [String]
        self.upvoters = value["upvoters"] as? [String: Double]
        self.downvoters = value["downvoters"] as? [String: Double]
        self.commenters = value["commenters"] as? [String: Int]
        self.savers = value["savers"] as? [String: Double]
        self.sharers = value["sharers"] as? [String: Double]
        self.notificationTokens = value["notificationTokens"] as? [String: String]
        self.changedSinceLastJob = value["changedSinceLastJob"] as? Bool
    }
}
