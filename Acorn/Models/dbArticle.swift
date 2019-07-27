//
//  dbArticle.swift
//  Acorn
//
//  Created by macOS on 24/11/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation

class dbArticle {
    var objectID: String
    var title: String?
    var source: String?
    var pubDate: Double?
    var imageUrl: String?
    var link: String?
    var author: String?
    var mainTheme: String?
    var voteCount: Int?
    var commentCount: Int?
    var writeDate: Double?
    var isSaved: Int?
    var htmlContent: String?
    
    init(uid: String, article: Article) {
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        
        self.objectID = article.objectID
        self.title = article.title
        self.source = article.source
        self.pubDate = article.pubDate
        self.imageUrl = article.imageUrl
        self.link = article.link
        self.author = article.author
        self.mainTheme = article.mainTheme
        self.voteCount = article.voteCount
        self.commentCount = article.commentCount
        self.writeDate = now
        self.isSaved = article.savers?[uid] != nil ? 1 : 0
        self.htmlContent = article.htmlContent
    }

    init(objectID: String, title: String?, source: String?, pubDate: Double?, imageUrl: String?, link: String?, author: String?, mainTheme: String?, voteCount: Int?, commentCount: Int?, writeDate: Double?, isSaved: Int?, htmlContent: String?) {
        
        self.objectID = objectID
        self.title = title
        self.source = source
        self.pubDate = pubDate
        self.imageUrl = imageUrl
        self.link = link
        self.author = author
        self.mainTheme = mainTheme
        self.voteCount = voteCount
        self.commentCount = commentCount
        self.writeDate = writeDate
        self.htmlContent = htmlContent
    }
}
