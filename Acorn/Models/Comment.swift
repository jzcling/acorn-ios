//
//  Comment.swift
//  Acorn
//
//  Created by macOS on 17/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation
import FirebaseUI
import Firebase

class Comment {
    var commentId: String
    var uid: String
    var userDisplayName: String
    var commentText: String?
    var imageUrl: String?
    var localImageUri: String?
    var pubDate: Double
    var isUrl: Bool
    var urlSource: String?
    var urlLink: String?
    var isReported: Bool? = false
    
    init(snapshot: DataSnapshot) {
        let value = snapshot.value as! [String: Any]
        self.commentId = snapshot.key
        self.uid = value["uid"] as! String
        self.userDisplayName = value["userDisplayName"] as! String
        self.commentText = value["commentText"] as? String
        self.imageUrl = value["imageUrl"] as? String
        self.localImageUri = value["localImageUri"] as? String
        self.pubDate = value["pubDate"] as! Double
        self.isUrl = value["isUrl"] as! Bool
        self.urlSource = value["urlSource"] as? String
        self.urlLink = value["urlLink"] as? String
        self.isReported = value["isReported"] as? Bool ?? false
    }
    
    init(commentId: String, uid: String, userDisplayName: String, commentText: String?, imageUrl: String?, localImageUri: String?, pubDate: Double, isUrl: Bool, urlSource: String?, urlLink: String?, isReported: Bool?) {
        self.commentId = commentId
        self.uid = uid
        self.userDisplayName = userDisplayName
        self.commentText = commentText
        self.imageUrl = imageUrl
        self.localImageUri = localImageUri
        self.pubDate = pubDate
        self.isUrl = isUrl
        self.urlSource = urlSource
        self.urlLink = urlLink
        self.isReported = isReported
    }
}
