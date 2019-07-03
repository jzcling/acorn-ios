//
//  AcornUser.swift
//  Acorn
//
//  Created by macOS on 18/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation
import Firebase

class AcornUser {
    var uid: String
    var displayName: String
    var token: String
    var email: String
    var status: Int
    var points: Double
    var targetPoints: Double?
    var creationTimeStamp: Double?
    var lastSignInTimeStamp: Double?
    var lastRecArticlesPushTime: Double?
    var lastRecArticlesScheduleTime: Double?
    var subscriptions: [String]
    var createdPosts: [String: Double]?
    var upvotedItems: [String: Double]?
    var downvotedItems: [String: Double]?
    var commentedItems: [String: Int]?
    var savedItems: [String: Double]?
    var sharedItems: [String: Double]?
    var subscriptionsCount: Int
    var createdPostsCount: Double?
    var upvotedItemsCount: Double?
    var downvotedItemsCount: Double?
    var commentedItemsCount: Double?
    var savedItemsCount: Double?
    var sharedItemsCount: Double?
    
    init(snapshot: DataSnapshot) {
        let value = snapshot.value as! [String: Any]
        uid = value["uid"] as! String
        displayName = value["displayName"] as! String
        token = value["token"] as! String
        email = value["email"] as! String
        status = value["status"] != nil ? value["status"] as! Int : 0
        points = value["points"] != nil ? value["points"] as! Double : 0.0
        targetPoints = value["targetPoints"] as? Double
        creationTimeStamp = value["creationTimeStamp"] as? Double
        lastSignInTimeStamp = value["lastSignInTimeStamp"] as? Double
        lastRecArticlesPushTime = value["lastRecArticlesPushTime"] as? Double
        lastRecArticlesScheduleTime = value["lastRecArticlesScheduleTime"] as? Double
        subscriptions = value["subscriptions"] as! [String]
        createdPosts = value["createdPosts"] as? [String: Double]
        upvotedItems = value["upvotedItems"] as? [String: Double]
        downvotedItems = value["downvotedItems"] as? [String: Double]
        commentedItems = value["commentedItems"] as? [String: Int]
        savedItems = value["savedItems"] as? [String: Double]
        sharedItems = value["sharedItems"] as? [String: Double]
        subscriptionsCount = value["subscriptionsCount"] as! Int
        createdPostsCount = value["createdPostsCount"] as? Double
        upvotedItemsCount = value["upvotedItemsCount"] as? Double
        downvotedItemsCount = value["downvotedItemsCount"] as? Double
        commentedItemsCount = value["commentedItemsCount"] as? Double
        savedItemsCount = value["savedItemsCount"] as? Double
        sharedItemsCount = value["sharedItemsCount"] as? Double
    }
}
