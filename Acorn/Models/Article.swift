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
    var category: [String]? = [String]()
    var theme: [String]? = [String]()
    var upvoters: [String: Double]? = [String: Double]()
    var downvoters: [String: Double]? = [String: Double]()
    var commenters: [String: Int]? = [String: Int]()
    var savers: [String: Double]? = [String: Double]()
    var sharers: [String: Double]? = [String: Double]()
    var notificationTokens: [String: String]? = [String: String]()
    var changedSinceLastJob: Bool? = true
    var isReported: Bool? = false
    
    init(snapshot: DataSnapshot) {
        let value = snapshot.value as! [String: Any]
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
        self.category = value["category"] as? [String] ?? [String]()
        self.theme = value["theme"] as? [String] ?? [String] ()
        self.upvoters = value["upvoters"] as? [String: Double] ?? [String: Double]()
        self.downvoters = value["downvoters"] as? [String: Double] ?? [String: Double]()
        self.commenters = value["commenters"] as? [String: Int] ?? [String: Int]()
        self.savers = value["savers"] as? [String: Double] ?? [String: Double]()
        self.sharers = value["sharers"] as? [String: Double] ?? [String: Double]()
        self.notificationTokens = value["notificationTokens"] as? [String: String] ?? [String: String]()
        self.changedSinceLastJob = value["changedSinceLastJob"] as? Bool ?? true
        self.isReported = value["isReported"] as? Bool ?? false
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
        self.category = value["category"] as? [String] ?? [String]()
        self.theme = value["theme"] as? [String] ?? [String]()
        self.upvoters = value["upvoters"] as? [String: Double] ?? [String: Double]()
        self.downvoters = value["downvoters"] as? [String: Double] ?? [String: Double]()
        self.commenters = value["commenters"] as? [String: Int] ?? [String: Int]()
        self.savers = value["savers"] as? [String: Double] ?? [String: Double]()
        self.sharers = value["sharers"] as? [String: Double] ?? [String: Double]()
        self.notificationTokens = value["notificationTokens"] as? [String: String] ?? [String: String]()
        self.changedSinceLastJob = value["changedSinceLastJob"] as? Bool ?? true
        self.isReported = value["isReported"] as? Bool ?? false
    }
}
