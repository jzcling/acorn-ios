//
//  LocalDb.swift
//  Acorn
//
//  Created by macOS on 24/11/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation
import SQLite

class LocalDb {
    
    static let instance = LocalDb()
    
    var localDb: Connection?
    
    let article_table = Table("article")
    let objectID = Expression<String>("objectID")
    let title = Expression<String?>("title")
    let source = Expression<String?>("source")
    let pubDate = Expression<Double?>("pubDate")
    let imageUrl = Expression<String?>("imageUrl")
    let link = Expression<String?>("link")
    let author = Expression<String?>("author")
    let mainTheme = Expression<String?>("mainTheme")
    let voteCount = Expression<Int?>("voteCount")
    let commentCount = Expression<Int?>("commentCount")
    let writeDate = Expression<Double?>("writeDate")
    let isSaved = Expression<Int?>("isSaved")
    let htmlContent = Expression<String?>("htmlContent")
    
    func openDatabase() {
        print("openDatabase")
        let dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        do {
            localDb = try Connection("\(dbPath)/localDb.sqlite3")
            
            try localDb?.run(article_table.create(ifNotExists: true) { t in
                t.column(objectID, primaryKey: true)
                t.column(title)
                t.column(source)
                t.column(pubDate)
                t.column(imageUrl)
                t.column(link)
                t.column(author)
                t.column(mainTheme)
                t.column(voteCount)
                t.column(commentCount)
                t.column(writeDate)
                t.column(isSaved)
                t.column(htmlContent)
            })
        } catch let error {
            print(error)
        }
    }
    
    func insertArticle(_ article: dbArticle) {
        do {
            try localDb?.run(article_table.insert(or: .replace, objectID <- article.objectID, title <- article.title, source <- article.source, pubDate <- article.pubDate, imageUrl <- article.imageUrl, link <- article.link, author <- article.author, mainTheme <- article.mainTheme, voteCount <- article.voteCount, commentCount <- article.commentCount, writeDate <- article.writeDate, isSaved <- article.isSaved, htmlContent <- article.htmlContent))
            print("articleInserted: \(article.title ?? ""), \(article.source ?? ""), \(article.htmlContent?.prefix(20) ?? "")")
        } catch let error {
            print(error)
        }
    }
    
    func getArticle(_ articleId: String) -> dbArticle? {
        do {
            if let article = try localDb!.pluck(article_table.filter(objectID == articleId)) {
                
                let localArticle = dbArticle(objectID: article[objectID], title: article[title], source: article[source], pubDate: article[pubDate], imageUrl: article[imageUrl], link: article[link], author: article[author], mainTheme: article[mainTheme], voteCount: article[voteCount], commentCount: article[commentCount], writeDate: article[writeDate], isSaved: article[isSaved], htmlContent: article[htmlContent])
                print("articleFetched: \(localArticle.title ?? ""), \(localArticle.source ?? ""), \(localArticle.htmlContent?.prefix(20) ?? "")")
                
                return localArticle
            }
        } catch let error {
            print(error)
        }
        return nil
    }
    
    func deleteArticle(_ articleId: String) {
        do {
            try localDb?.run(article_table.filter(objectID == articleId).delete())
        } catch let error {
            print(error)
        }
    }
    
    func deleteOldArticles(cutOffDate: Double) {
        do {
            try localDb?.run(article_table.filter(writeDate < cutOffDate).filter(isSaved != 1).delete())
        } catch let error {
            print(error)
        }
    }
    
    func deleteAll() {
        do {
            try localDb?.run(article_table.delete())
        } catch let error {
            print(error)
        }
    }
}
