//
//  Video.swift
//  Acorn
//
//  Created by macOS on 29/10/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation
import FirebaseUI
import Firebase

class Video {
    var objectID: String
    var type: String
    var postAuthorUid: String?
    var postAuthor: String?
    var postText: String?
    var postVideoUrl: String?
    var postDate: Double?
    var title: String?
    var source: String?
    var pubDate: Double
    var videoUrl: String?
    var youtubeVideoId: String?
    var author: String?
    var mainTheme: String?
    var trendingIndex: String?
    var voteCount: Int? = 0
    var commentCount: Int? = 0
    var saveCount: Int? = 0
    var shareCount: Int? = 0
    var viewCount: Int? = 0
    var category: [String]? = [String]()
    var theme: [String]? = [String]()
    var upvoters: [String: Double]? = [String: Double]()
    var downvoters: [String: Double]? = [String: Double]()
    var commenters: [String: Int]? = [String: Int]()
    var savers: [String: Double]? = [String: Double]()
    var sharers: [String: Double]? = [String: Double]()
    var viewedBy: [String: Double]? = [String: Double]()
    var notificationTokens: [String: String]? = [String: String]()
    var changedSinceLastJob: Bool? = true
    var isReported: Bool? = false
    var starRatingCount: Double?
    var starRatingAverage: Double?
    var youtubeViewCount: Double?
    
    init(snapshot: DataSnapshot) {
        let value = snapshot.value as! [String: Any]
        self.objectID = value["objectID"] as! String
        self.type = value["type"] as! String
        self.postAuthorUid = value["postAuthorUid"] as? String
        self.postAuthor = value["postAuthor"] as? String
        self.postText = value["postText"] as? String
        
        let postVideoUrl = value["postVideoUrl"] as? String
        self.postVideoUrl = postVideoUrl
        self.postDate = value["postDate"] as? Double
        self.title = value["title"] as? String
        self.source = value["source"] as? String
        self.pubDate = value["pubDate"] as! Double
        
        let videoUrl = value["videoUrl"] as? String
        self.videoUrl = videoUrl
        
        let youtubeVideoId = value["youtubeVideoId"] as? String
        self.youtubeVideoId = youtubeVideoId
        self.author = value["author"] as? String
        self.mainTheme = value["mainTheme"] as? String
        self.trendingIndex = value["trendingIndex"] as? String
        self.voteCount = value["voteCount"] as? Int ?? 0
        self.commentCount = value["commentCount"] as? Int ?? 0
        self.saveCount = value["saveCount"] as? Int ?? 0
        self.shareCount = value["shareCount"] as? Int ?? 0
        self.viewCount = value["viewCount"] as? Int ?? 0
        self.category = value["category"] as? [String] ?? [String]()
        self.theme = value["theme"] as? [String] ?? [String] ()
        self.upvoters = value["upvoters"] as? [String: Double] ?? [String: Double]()
        self.downvoters = value["downvoters"] as? [String: Double] ?? [String: Double]()
        self.commenters = value["commenters"] as? [String: Int] ?? [String: Int]()
        self.savers = value["savers"] as? [String: Double] ?? [String: Double]()
        self.sharers = value["sharers"] as? [String: Double] ?? [String: Double]()
        self.viewedBy = value["viewedBy"] as? [String: Double] ?? [String: Double]()
        self.notificationTokens = value["notificationTokens"] as? [String: String] ?? [String: String]()
        self.changedSinceLastJob = value["changedSinceLastJob"] as? Bool ?? true
        self.isReported = value["isReported"] as? Bool ?? false
        self.starRatingCount = value["starRatingCount"] as? Double ?? 0
        self.starRatingAverage = value["starRatingAverage"] as? Double ?? 0
        self.youtubeViewCount = value["youtubeViewCount"] as? Double ?? 0
    }
    
    init(json: [String: Any]) {
        let value = json
        self.objectID = value["objectID"] as! String
        self.type = value["type"] as! String
        self.postAuthorUid = value["postAuthorUid"] as? String
        self.postAuthor = value["postAuthor"] as? String
        self.postText = value["postText"] as? String
        let postVideoUrl = value["postVideoUrl"] as? String
        self.postVideoUrl = postVideoUrl
        self.postDate = value["postDate"] as? Double
        self.title = value["title"] as? String
        self.source = value["source"] as? String
        self.pubDate = value["pubDate"] as! Double
        let videoUrl = value["videoUrl"] as? String
        self.videoUrl = videoUrl
        let youtubeVideoId = value["youtubeVideoId"] as? String
        self.youtubeVideoId = youtubeVideoId
        self.author = value["author"] as? String
        self.mainTheme = value["mainTheme"] as? String
        self.trendingIndex = value["trendingIndex"] as? String
        self.voteCount = value["voteCount"] as? Int ?? 0
        self.commentCount = value["commentCount"] as? Int ?? 0
        self.saveCount = value["saveCount"] as? Int ?? 0
        self.shareCount = value["shareCount"] as? Int ?? 0
        self.viewCount = value["viewCount"] as? Int ?? 0
        self.category = value["category"] as? [String] ?? [String]()
        self.theme = value["theme"] as? [String] ?? [String]()
        self.upvoters = value["upvoters"] as? [String: Double] ?? [String: Double]()
        self.downvoters = value["downvoters"] as? [String: Double] ?? [String: Double]()
        self.commenters = value["commenters"] as? [String: Int] ?? [String: Int]()
        self.savers = value["savers"] as? [String: Double] ?? [String: Double]()
        self.sharers = value["sharers"] as? [String: Double] ?? [String: Double]()
        self.viewedBy = value["viewedBy"] as? [String: Double] ?? [String: Double]()
        self.notificationTokens = value["notificationTokens"] as? [String: String] ?? [String: String]()
        self.changedSinceLastJob = value["changedSinceLastJob"] as? Bool ?? true
        self.isReported = value["isReported"] as? Bool ?? false
        self.starRatingCount = value["starRatingCount"] as? Double ?? 0
        self.starRatingAverage = value["starRatingAverage"] as? Double ?? 0
        self.youtubeViewCount = value["youtubeViewCount"] as? Double ?? 0
    }
    
    init(article: Article) {
        self.objectID = article.objectID
        self.type = article.type
        self.postAuthorUid = article.postAuthorUid
        self.postAuthor = article.postAuthor
        self.postText = article.postText
        self.postVideoUrl = article.postText != nil ? article.link : nil
        self.videoUrl = article.postText != nil ? nil : article.link
        self.postDate = article.postDate
        self.title = article.title
        self.source = article.source
        self.pubDate = article.pubDate
        self.author = article.author
        self.mainTheme = article.mainTheme
        self.trendingIndex = article.trendingIndex
        self.voteCount = article.voteCount
        self.commentCount = article.commentCount
        self.saveCount = article.saveCount
        self.shareCount = article.shareCount
        self.viewCount = article.openCount
        self.category = article.category
        self.theme = article.theme
        self.upvoters = article.upvoters
        self.downvoters = article.downvoters
        self.commenters = article.commenters
        self.savers = article.savers
        self.sharers = article.sharers
        self.viewedBy = article.openedBy
        self.notificationTokens = article.notificationTokens
        self.changedSinceLastJob = article.changedSinceLastJob
        self.isReported = article.isReported
        self.youtubeViewCount = Double(article.readTime ?? 0)
    }
}
