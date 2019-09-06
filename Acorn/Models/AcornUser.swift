//
//  User.swift
//  Acorn
//
//  Created by macOS on 18/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation
import FirebaseUI
import Firebase

class AcornUser {
    var uid: String
    var displayName: String
    var token: String
    var email: String
    var isEmailVerified: Bool
    var device: String?
    var status: Int = 0
    var points: Double = 0
    var targetPoints: Double = 10
    var creationTimeStamp: Double?
    var lastSignInTimeStamp: Double?
    var lastRecArticlesPushTime: Double = 0
    var lastRecArticlesScheduleTime: Double = 0
    var lastRecDealsPushTime: Double = 0
    var lastRecDealsScheduleTime: Double = 0
    var subscriptions: [String] = [String]()
    var createdPosts: [String: Double] = [String: Double]()
    var upvotedItems: [String: Double] = [String: Double]()
    var downvotedItems: [String: Double] = [String: Double]()
    var commentedItems: [String: Int] = [String: Int]()
    var savedItems: [String: Double] = [String: Double]()
    var sharedItems: [String: Double] = [String: Double]()
    var openedArticles: [String: Double] = [String: Double]()
    var openedThemes: [String: Int] = [String: Int]()
    var viewedVideos: [String: Double] = [String: Double]()
    var subscriptionsCount: Int = 0
    var createdPostsCount: Int = 0
    var upvotedItemsCount: Int = 0
    var downvotedItemsCount: Int = 0
    var commentedItemsCount: Int = 0
    var savedItemsCount: Int = 0
    var sharedItemsCount: Int = 0
    var openedSinceLastReport: Bool
    var premiumStatus: [String: Double] = [String: Double]()
    var referredBy: String?
    var referredUsers: [String: Double] = [String: Double]()
    
    init(snapshot: DataSnapshot) {
        let value = snapshot.value as! [String: Any]
        self.uid = value["uid"] as! String
        self.displayName = value["displayName"] as! String
        self.token = value["token"] as! String
        self.email = value["email"] as! String
        self.isEmailVerified = value["isEmailVerified"] as? Bool ?? false
        self.device = value["device"] as? String
        self.status = value["status"] != nil ? value["status"] as! Int : 0
        self.points = value["points"] != nil ? value["points"] as! Double : 0
        self.targetPoints = value["targetPoints"] as? Double ?? 0
        self.creationTimeStamp = value["creationTimeStamp"] as? Double
        self.lastSignInTimeStamp = value["lastSignInTimeStamp"] as? Double
        self.lastRecArticlesPushTime = value["lastRecArticlesPushTime"] as? Double ?? 0
        self.lastRecArticlesScheduleTime = value["lastRecArticlesScheduleTime"] as? Double ?? 0
        self.lastRecDealsPushTime = value["lastRecDealsPushTime"] as? Double ?? 0
        self.lastRecDealsScheduleTime = value["lastRecDealsScheduleTime"] as? Double ?? 0
        self.subscriptions = value["subscriptions"] as? [String] ?? [String]()
        self.createdPosts = value["createdPosts"] as? [String: Double] ?? [String: Double]()
        self.upvotedItems = value["upvotedItems"] as? [String: Double] ?? [String: Double]()
        self.downvotedItems = value["downvotedItems"] as? [String: Double] ?? [String: Double]()
        self.commentedItems = value["commentedItems"] as? [String: Int] ?? [String: Int]()
        self.savedItems = value["savedItems"] as? [String: Double] ?? [String: Double]()
        self.sharedItems = value["sharedItems"] as? [String: Double] ?? [String: Double]()
        self.openedArticles = value["openedArticles"] as? [String: Double] ?? [String: Double]()
        self.viewedVideos = value["viewedVideos"] as? [String:Double] ?? [String: Double]()
        self.openedThemes = value["openedThemes"] as? [String: Int] ?? [String: Int]()
        self.subscriptionsCount = value["subscriptionsCount"] as? Int ?? 0
        self.createdPostsCount = value["createdPostsCount"] as? Int ?? 0
        self.upvotedItemsCount = value["upvotedItemsCount"] as? Int ?? 0
        self.downvotedItemsCount = value["downvotedItemsCount"] as? Int ?? 0
        self.commentedItemsCount = value["commentedItemsCount"] as? Int ?? 0
        self.savedItemsCount = value["savedItemsCount"] as? Int ?? 0
        self.sharedItemsCount = value["sharedItemsCount"] as? Int ?? 0
        self.openedSinceLastReport = value["openedSinceLastReport"] as? Bool ?? false
        self.premiumStatus = value["premiumStatus"] as? [String: Double] ?? [String: Double]()
        self.referredBy = value["referredBy"] as? String
        self.referredUsers = value["referredUsers"] as? [String: Double] ?? [String: Double]()
    }
    
    init(uid: String, displayName: String, token: String, email: String, isEmailVerified: Bool, device: String, creationTimeStamp: Double, lastSignInTimeStamp: Double, openedSinceLastReport: Bool) {
        self.uid = uid
        self.displayName = displayName
        self.token = token
        self.email = email
        self.isEmailVerified = isEmailVerified
        self.device = device
        self.creationTimeStamp = creationTimeStamp
        self.lastSignInTimeStamp = lastSignInTimeStamp
        self.openedSinceLastReport = openedSinceLastReport
    }
    
    func toDict() -> [String: Any?] {
        var user = [String: Any?]()
        
        user["uid"] = self.uid
        user["displayName"] = self.displayName
        user["token"] = self.token
        user["email"] = self.email
        user["isEmailVerified"] = self.isEmailVerified
        user["device"] = self.device
        user["status"] = self.status
        user["points"] = self.points
        user["targetPoints"] = self.targetPoints
        user["creationTimeStamp"] = self.creationTimeStamp
        user["lastSignInTimeStamp"] = self.lastSignInTimeStamp
        user["lastRecArticlesPushTime"] = self.lastRecArticlesPushTime
        user["lastRecArticlesScheduleTime"] = self.lastRecArticlesScheduleTime
        user["lastRecDealsPushTime"] = self.lastRecDealsPushTime
        user["lastRecDealsScheduleTime"] = self.lastRecDealsScheduleTime
        user["subscriptions"] = self.subscriptions
        user["createdPosts"] = self.createdPosts
        user["upvotedItems"] = self.upvotedItems
        user["downvotedItems"] = self.downvotedItems
        user["commentedItems"] = self.commentedItems
        user["savedItems"] = self.savedItems
        user["sharedItems"] = self.sharedItems
        user["openedArticles"] = self.openedArticles
        user["viewedVideos"] = self.viewedVideos
        user["openedThemes"] = self.openedThemes
        user["subscriptionsCount"] = self.subscriptionsCount
        user["createPostsCount"] = self.createdPostsCount
        user["upvotedItemsCount"] = self.upvotedItemsCount
        user["downvotedItemsCount"] = self.downvotedItemsCount
        user["commentedItemsCount"] = self.commentedItemsCount
        user["savedItemsCount"] = self.savedItemsCount
        user["sharedItemsCount"] = self.sharedItemsCount
        user["openedSinceLastReport"] = self.openedSinceLastReport
        user["premiumStatus"] = self.premiumStatus
        user["referredBy"] = self.referredBy
        
        return user
    }
    
    func toDictForUpdate() -> [String: Any?] {
        var user = [String: Any?]()
        
        user["uid"] = self.uid
        user["displayName"] = self.displayName
        user["token"] = self.token
        user["email"] = self.email
        user["isEmailVerified"] = self.isEmailVerified
        user["device"] = self.device
        user["creationTimeStamp"] = self.creationTimeStamp
        user["lastSignInTimeStamp"] = self.lastSignInTimeStamp
        user["openedSinceLastReport"] = self.openedSinceLastReport
        user["targetPoints"] = self.targetPoints
        
        return user
    }
}
