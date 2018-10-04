//
//  DataSource.swift
//  Acorn
//
//  Created by macOS on 6/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation
import FirebaseUI
import Firebase
import AlgoliaSearch

class DataSource {
    
    static let instance = DataSource()
    
    var algoliaApiKey: String?
    var algoliaClient: Client?
    var algoliaIndex: Index?
    
    let limit = 10 as UInt
    
    let defaults = UserDefaults.standard
    var themeKey: String?
    var themeFilters: String?
    
    lazy var database = Database.database()
    lazy var storage = Storage.storage()
    
    lazy var user = Auth.auth().currentUser!
    lazy var uid = user.uid
    lazy var userDisplayName = user.displayName
    
    lazy var articleRef = self.database.reference(withPath: "article")
    lazy var searchRef = self.database.reference(withPath: "search")
    lazy var commentRef = self.database.reference(withPath: "comment")
    lazy var userRef = self.database.reference(withPath: "user/\(uid)")
    lazy var postRef = self.database.reference(withPath: "article")
    lazy var commentsPreferenceRef = self.database.reference(withPath: "preference/commentsNotificationValue/\(uid)")
    lazy var recArticlesPreferenceRef = self.database.reference(withPath: "preference/recArticlesNotificationValue/\(uid)")
    lazy var algoliaRef = self.database.reference(withPath: "algoliaApiKey")
    lazy var reportRef = self.database.reference(withPath: "reported")
    
    lazy var userStorage = self.storage.reference(withPath: uid)
    
    var articleList = [Article]()
    var observedFeedQueries = [DatabaseQuery]()
    var observedArticlesQueries = [String: DatabaseQuery]()
    
    
    // Setup
    func setupAlgoliaClient(onComplete: @escaping () -> ()) {
        algoliaRef.observeSingleEvent(of: .value) { (snap) in
            guard let apiKey = snap.value as? String else { return }
            
            self.algoliaApiKey = apiKey
            self.algoliaClient = Client(appID: "O96PPLSF19", apiKey: apiKey)
            self.algoliaIndex = self.algoliaClient?.index(withName: "article")
            
            onComplete()
        }
    }
    
    func getUser(user: User, onComplete: @escaping (AcornUser?) -> ()) {
        self.database.reference(withPath: "user/\(user.uid)").observeSingleEvent(of: .value) { (snap) in
            if snap.exists() {
                let user = AcornUser(snapshot: snap)
                onComplete(user)
            } else {
                onComplete(nil)
            }
        }
    }
    
    func setUser(_ user: [String: Any?]) {
        userRef.setValue(user)
    }
    
    func getThemeSubscriptions(user: User, onComplete: (([String]) -> ())?) {
        let uid = user.uid
        let subsRef = self.database.reference(withPath: "user/\(uid)/subscriptions")
        var themePrefs = [String]()
        
        subsRef.observeSingleEvent(of: .value) { (snap) in
            if let subs = snap.value as? [String] {
                themePrefs = subs.sorted()
                var tempThemeKey: String
                var tempThemeFilters: String
                tempThemeKey = themePrefs[0]
                tempThemeFilters = "mainTheme: \"\(themePrefs[0])\""
                for theme in themePrefs[1 ..< themePrefs.endIndex] {
                    tempThemeKey += "_\(theme)"
                    tempThemeFilters += " OR mainTheme: \"\(theme)\""
                }
                self.themeKey = tempThemeKey
                self.themeFilters = tempThemeFilters
                self.defaults.set(self.themeFilters, forKey: "themeFilters")
                self.defaults.set(self.themeKey, forKey: "themeKey")
                
                
                if let _ = onComplete { onComplete!(themePrefs) }
            } else {
                self.defaults.set(nil, forKey: "themeFilters")
                self.defaults.set(nil, forKey: "themeKey")
                
                
                if let _ = onComplete { onComplete!(themePrefs) }
            }
        }
    }
    
    func setThemeSubscriptions(_ themePrefs: [String]) {
        let subsRef = userRef.child("subscriptions")
        let subsCountRef = userRef.child("subscriptionsCount")
        
        subsRef.setValue(themePrefs)
        subsCountRef.setValue(themePrefs.count)
    }
    
    
    // Feed
    func observeArticles(query: DatabaseQuery, onComplete: @escaping ([Article]) -> ()) {
        var articles = [Article]()
        var articleIds = [String]()
        
        query.observe(.childAdded) { (snap) in
            let article = Article(snapshot: snap)
            
            if !articleIds.contains(snap.key) {
                let isReported = article.isReported ?? false
                if !isReported {
                    articles.append(article)
                    articleIds.append(snap.key)
                }
            }
            onComplete(articles)
        }
        
        query.observe(.childChanged) { (snap) in
            let article = Article(snapshot: snap)
            
            if let index = articleIds.index(of: snap.key) {
                let isReported = article.isReported ?? false
                if isReported {
                    articles.remove(at: index)
                    articleIds.remove(at: index)
                } else {
                    articles[index] = article
                }
            }
            onComplete(articles)
        }
        
        query.observe(.childRemoved) { (snap) in
            if let index = articleIds.index(of: snap.key) {
                articles.remove(at: index)
                articleIds.remove(at: index)
            }
            onComplete(articles)
        }
        
        query.observe(.childMoved) { (snap, previousChildKey) in
            if let index = articleIds.index(of: snap.key) {
                articleIds.remove(at: index)
                articles.remove(at: index)
            }
            let newIndex = (previousChildKey != nil) ? articleIds.index(of: previousChildKey!)! + 1 : 0
            articleIds.insert(snap.key, at: newIndex)
            articles.insert(Article(snapshot: snap), at: newIndex)
            onComplete(articles)
        }
    }
    
    func getSubscriptionsFeed(onComplete: @escaping ([Article]) -> ()) {
        themeKey = defaults.string(forKey: "themeKey")
        themeFilters = defaults.string(forKey: "themeFilters")
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        setupAlgoliaClient {
            if self.themeKey != nil {
                let hitsRef = self.searchRef.child(self.themeKey!).child("hits")
                let initQuery = self.searchRef.child(self.themeKey!).child("lastQueryTimestamp")
                initQuery.observeSingleEvent(of: .value) { (lastQuerySnap) in
                    if let lastQueryTimestamp = lastQuerySnap.value as? Double {
                        let timeElapsed = DateUtils.hoursSince(unixTimestamp: lastQueryTimestamp)
                        if timeElapsed >= 3 {
                            
                            let algoliaQuery = Query()
                            algoliaQuery.filters = self.themeFilters
                            self.algoliaIndex?.search(algoliaQuery) { (content, error) in
                                if error == nil {
                                    self.searchRef.child(self.themeKey!).setValue(content, withCompletionBlock: { (error, ref) in
                                        initQuery.setValue(now)
                                        let query = hitsRef.queryOrdered(byChild: "pubDate").queryLimited(toFirst: self.limit)
                                        query.keepSynced(true)
                                        self.observedFeedQueries.append(query)
                                        self.observeArticles(query: query, onComplete: onComplete)
                                    })
                                }
                            }
                        } else {
                            
                            let query = hitsRef.queryOrdered(byChild: "pubDate").queryLimited(toFirst: self.limit)
                            query.keepSynced(true)
                            self.observedFeedQueries.append(query)
                            self.observeArticles(query: query, onComplete: onComplete)
                        }
                    } else {
                        
                        let algoliaQuery = Query()
                        algoliaQuery.filters = self.themeFilters
                        self.algoliaIndex?.search(algoliaQuery) { (content, error) in
                            if error == nil {
                                self.searchRef.child(self.themeKey!).setValue(content, withCompletionBlock: { (error, ref) in
                                    initQuery.setValue(now)
                                    let query = hitsRef.queryOrdered(byChild: "pubDate").queryLimited(toFirst: self.limit)
                                    query.keepSynced(true)
                                    self.observedFeedQueries.append(query)
                                    self.observeArticles(query: query, onComplete: onComplete)
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getSubscriptionsFeed(startAt: Double, onComplete: @escaping ([Article]) -> ()) {
        themeKey = defaults.string(forKey: "themeKey")
        let hitsRef = searchRef.child(themeKey!).child("hits")
        let query = hitsRef.queryOrdered(byChild: "pubDate").queryLimited(toFirst: self.limit + 1).queryStarting(atValue: startAt)
        query.keepSynced(true)
        self.observedFeedQueries.append(query)
        self.observeArticles(query: query, onComplete: onComplete)
    }
    
    func observeSingleArticle(articleId: String, onComplete: @escaping ((Article) -> ())) {
        let query = articleRef.child(articleId)
        query.observe(.value) { (snap) in
            onComplete(Article(snapshot: snap))
        }
        self.observedArticlesQueries[articleId] = query
    }
    
    func getRecentFeed(onComplete: @escaping ([Article]) -> ()) {
        let query = articleRef.queryOrdered(byChild: "pubDate").queryLimited(toFirst: limit)
        query.keepSynced(true)
        observedFeedQueries.append(query)
        observeArticles(query: query, onComplete: onComplete)
    }
    
    func getRecentFeed(startAt: Double, onComplete: @escaping ([Article]) -> ()) {
        let query = articleRef.queryOrdered(byChild: "pubDate").queryLimited(toFirst: limit + 1).queryStarting(atValue: startAt)
        query.keepSynced(true)
        observedFeedQueries.append(query)
        observeArticles(query: query, onComplete: onComplete)
    }
    
    func getTrendingFeed(onComplete: @escaping ([Article]) -> ()) {
        let query = articleRef.queryOrdered(byChild: "trendingIndex").queryLimited(toFirst: limit)
        query.keepSynced(true)
        observedFeedQueries.append(query)
        observeArticles(query: query, onComplete: onComplete)
    }
    
    func getTrendingFeed(startAt: String, onComplete: @escaping ([Article]) -> ()) {
        let query = articleRef.queryOrdered(byChild: "trendingIndex").queryLimited(toFirst: limit + 1).queryStarting(atValue: startAt)
        query.keepSynced(true)
        observedFeedQueries.append(query)
        observeArticles(query: query, onComplete: onComplete)
    }
    
    func getSavedFeed(startAt: Int, onComplete: @escaping ([Article]) -> ()) {
        var savedList = [String]()
        var articles = [Article]()
        
        let savedQuery = userRef.child("savedItems")
        savedQuery.observeSingleEvent(of: .value) { (savedSnap) in
            if let savedItems = savedSnap.value as? [String: Double] {
                savedList.append(contentsOf: savedItems.keys)
                if savedList.count == 0 { return }
                var counter = 0
                let endIndex = min(startAt + Int(self.limit), savedList.count)
                for saved in savedList[startAt ..< endIndex] {
                    counter += 1
                    let query = self.articleRef.child(saved)
                    query.keepSynced(true)
                    self.observedFeedQueries.append(query)
                    query.observe(.value, with: { (articleSnap) in
                        articles.append(Article(snapshot: articleSnap))
                        if (saved == savedList.last || counter == self.limit) {
                            onComplete(articles)
                        }
                    })
                }
            }
        }
    }
    
    func removeFeedObservers() {
        for query in observedFeedQueries {
            
            query.removeAllObservers()
        }
        observedFeedQueries.removeAll()
    }
    
    func removeArticleObserver(_ articleId: String) {
        if let query = observedArticlesQueries[articleId] {
            
            query.removeAllObservers()
            observedArticlesQueries.removeValue(forKey: articleId)
        }
    }
    
    func reportPost(_ article: Article) {
        articleRef.child("\(article.objectID)/isReported").setValue(true)
        reportRef.child("article/\(article.objectID)").setValue(article.postAuthorUid)
        
        if let posterUid = article.postAuthorUid {
            let reportedUserRef = reportRef.child("user/\(posterUid)")
            reportedUserRef.observeSingleEvent(of: .value) { (snap) in
                let count = snap.value as? Int ?? 0
                reportedUserRef.setValue(count + 1)
            }
        }
    }
    
    
    // Recommended Articles
    func getRecommendedArticles(onComplete: @escaping ([Article]) -> ()) {
        
        themeKey = defaults.string(forKey: "themeKey")
        themeFilters = defaults.string(forKey: "themeFilters")
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        setupAlgoliaClient {
            if self.themeKey != nil {
                let hitsRef = self.searchRef.child(self.themeKey!).child("hits")
                let initQuery = self.searchRef.child(self.themeKey!).child("lastQueryTimestamp")
                initQuery.observeSingleEvent(of: .value) { (lastQuerySnap) in
                    if let lastQueryTimestamp = lastQuerySnap.value as? Double {
                        let timeElapsed = DateUtils.hoursSince(unixTimestamp: lastQueryTimestamp)
                        if timeElapsed >= 3 {
                            
                            let algoliaQuery = Query()
                            algoliaQuery.filters = self.themeFilters
                            self.algoliaIndex?.search(algoliaQuery) { (content, error) in
                                if error == nil {
                                    self.searchRef.child(self.themeKey!).setValue(content, withCompletionBlock: { (error, ref) in
                                        initQuery.setValue(now)
                                        let query = hitsRef.queryLimited(toFirst: 5)
                                        var articles = [Article]()
                                        query.observe(.childAdded, with: { (snap) in
                                            let article = Article(snapshot: snap)
                                            articles.append(article)
                                            if articles.count == 5 {
                                                query.removeAllObservers()
                                                onComplete(articles)
                                            }
                                        })
                                    })
                                }
                            }
                        } else {
                            
                            let query = hitsRef.queryLimited(toFirst: 5)
                            var articles = [Article]()
                            query.observe(.childAdded, with: { (snap) in
                                let article = Article(snapshot: snap)
                                articles.append(article)
                                
                                if articles.count == 5 {
                                    query.removeAllObservers()
                                    onComplete(articles)
                                }
                            })
                        }
                    } else {
                        
                        let algoliaQuery = Query()
                        algoliaQuery.filters = self.themeFilters
                        self.algoliaIndex?.search(algoliaQuery) { (content, error) in
                            if error == nil {
                                self.searchRef.child(self.themeKey!).setValue(content, withCompletionBlock: { (error, ref) in
                                    initQuery.setValue(now)
                                    let query = hitsRef.queryLimited(toFirst: 5)
                                    var articles = [Article]()
                                    query.observe(.childAdded, with: { (snap) in
                                        let article = Article(snapshot: snap)
                                        articles.append(article)
                                        if articles.count == 5 {
                                            query.removeAllObservers()
                                            onComplete(articles)
                                        }
                                    })
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    // Feed Cells
    func updateArticleVote(article: Article, actionIsUpvote: Bool, wasUpvoted: Bool, wasDownvoted: Bool, onComplete: @escaping () -> ()) {
        let query = articleRef.child(article.objectID)
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        
        query.runTransactionBlock({ (mutableData) -> TransactionResult in
            if var article = mutableData.value as? [String: Any] {
                var upvoters = article["upvoters"] as? [String: Double] ?? [:]
                var downvoters = article["downvoters"] as? [String: Double] ?? [:]
                var voteCount = article["voteCount"] as? Int ?? 0
                
                if (actionIsUpvote && wasUpvoted) {
                    upvoters.removeValue(forKey: self.uid)
                } else if (actionIsUpvote && wasDownvoted) {
                    upvoters[self.uid] = now
                    downvoters.removeValue(forKey: self.uid)
                } else if (actionIsUpvote && !wasUpvoted && !wasDownvoted) {
                    upvoters[self.uid] = now
                } else if (!actionIsUpvote && wasUpvoted) {
                    upvoters.removeValue(forKey: self.uid)
                    downvoters[self.uid] = now
                } else if (!actionIsUpvote && wasDownvoted) {
                    downvoters.removeValue(forKey: self.uid)
                } else if (!actionIsUpvote && !wasUpvoted && !wasDownvoted) {
                    downvoters[self.uid] = now
                }
                
                voteCount = upvoters.count - downvoters.count
                
                article["upvoters"] = upvoters as Any?
                article["downvoters"] = downvoters as Any?
                article["voteCount"] = voteCount as Any?
                article["changedSinceLastJob"] = true as Any?
                
                mutableData.value = article
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                
            }
            
            onComplete()
        })
    }
    
    func updateUserVote(article: Article, actionIsUpvote: Bool, onComplete: @escaping () -> ()) {
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        
        userRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            if var user = mutableData.value as? [String: Any] {
                var upvotedItems = user["upvotedItems"] as? [String: Double] ?? [:]
                var downvotedItems = user["downvotedItems"] as? [String: Double] ?? [:]
                var upvotedItemsCount = user["upvotedItemsCount"] as? Int ?? 0
                var downvotedItemsCount = user["downvotedItemsCount"] as? Int ?? 0
                var points = user["points"] as? Double ?? 0
                
                if actionIsUpvote {
                    if let _ = upvotedItems[self.uid] {
                        upvotedItems.removeValue(forKey: self.uid)
                        points = points - 1
                    } else {
                        upvotedItems[self.uid] = now
                        downvotedItems.removeValue(forKey: self.uid)
                        points = points + 1
                    }
                } else {
                    if let _ = downvotedItems[self.uid] {
                        downvotedItems.removeValue(forKey: self.uid)
                        points = points - 1
                    } else {
                        upvotedItems.removeValue(forKey: self.uid)
                        downvotedItems[self.uid] = now
                        points = points + 1
                    }
                }
                
                upvotedItemsCount = upvotedItems.count
                downvotedItemsCount = downvotedItems.count
                
                user["upvotedItems"] = upvotedItems as Any?
                user["downvotedItems"] = downvotedItems as Any?
                user["upvotedItemsCount"] = upvotedItemsCount as Any?
                user["downvotedItemsCount"] = downvotedItemsCount as Any?
                user["points"] = points as Any?
                
                mutableData.value = user
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                
            }
            
            onComplete()
        })
    }
    
    func updateArticleSave(article: Article, onComplete: @escaping () -> ()) {
        let query = articleRef.child(article.objectID)
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        
        query.runTransactionBlock({ (mutableData) -> TransactionResult in
            if var article = mutableData.value as? [String: Any] {
                var savers = article["savers"] as? [String: Double] ?? [:]
                var saveCount = article["saveCount"] as? Int ?? 0
                
                if let _ = savers[self.uid] {
                    savers.removeValue(forKey: self.uid)
                } else {
                    savers[self.uid] = now
                }
                saveCount = savers.count
                
                article["savers"] = savers as Any?
                article["saveCount"] = saveCount as Any?
                article["changedSinceLastJob"] = true as Any?
                
                mutableData.value = article
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                
            }
            
            onComplete()
        })
    }
    
    func updateUserSave(article: Article, onComplete: @escaping () -> ()) {
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        
        userRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            if var user = mutableData.value as? [String: Any] {
                var savedItems = user["savedItems"] as? [String: Double] ?? [:]
                var savedItemsCount = user["savedItemsCount"] as? Int ?? 0
                
                if let _ = savedItems[article.objectID] {
                    savedItems.removeValue(forKey: article.objectID)
                } else {
                    savedItems[article.objectID] = now
                }
                savedItemsCount = savedItems.count
                
                user["savedItems"] = savedItems as Any?
                user["savedItemsCount"] = savedItemsCount as Any?
                
                mutableData.value = user
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                
            }
            
            onComplete()
        })
    }
    
    
    // Comments
    func observeComments(query: DatabaseQuery, onComplete: @escaping ([Comment]) -> ()) {
        var comments = [Comment]()
        var commentIds = [String]()
        
        query.observe(.childAdded) { (snap) in
            let comment = Comment(snapshot: snap)
            
            if !commentIds.contains(snap.key) {
                comments.append(comment)
                commentIds.append(snap.key)
            }
            onComplete(comments)
        }
        
        query.observe(.childChanged) { (snap) in
            let comment = Comment(snapshot: snap)
            
            if let index = commentIds.index(of: snap.key) {
                comments[index] = comment
            }
            onComplete(comments)
        }
        
        query.observe(.childRemoved) { (snap) in
            if let index = commentIds.index(of: snap.key) {
                comments.remove(at: index)
                commentIds.remove(at: index)
            }
            onComplete(comments)
        }
        
        query.observe(.childMoved) { (snap, previousChildKey) in
            if let index = commentIds.index(of: snap.key) {
                commentIds.remove(at: index)
                comments.remove(at: index)
            }
            let newIndex = (previousChildKey != nil) ? commentIds.index(of: previousChildKey!)! + 1 : 0
            commentIds.insert(snap.key, at: newIndex)
            comments.insert(Comment(snapshot: snap), at: newIndex)
            onComplete(comments)
        }
    }
    
    func getArticleComments(_ articleId: String, onComplete: @escaping ([Comment]) -> ()) {
        let query = commentRef.child(articleId)
        observeComments(query: query, onComplete: onComplete)
    }
    
    func removeCommentObservers(_ articleId: String) {
        commentRef.child(articleId).removeAllObservers()
    }
    
    func follow(articleId: String) {
        var token: String?
        
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                
            } else if let result = result {
                token = result.token
                let query = self.articleRef.child("\(articleId)/notificationTokens/\(self.uid)")
                query.setValue(token)
            }
        }
    }
    
    func unfollow(articleId: String) {
        let query = self.articleRef.child("\(articleId)/notificationTokens/\(self.uid)")
        query.removeValue()
    }
    
    func sendComment(articleId: String, commentText: String?, commentImageData: Data?, onComplete: @escaping () -> (), onError: @escaping (String) -> ()) {
        let commentRef = self.database.reference(withPath: "comment/\(articleId)")
        
        let now = -floor(Double(Date().timeIntervalSince1970 * 1000))
        let key = commentRef.childByAutoId().key
        
        var commentAsDict: [String: Any] = [
            "uid": uid,
            "userDisplayName": userDisplayName!,
            "commentText": commentText ?? "",
            "pubDate": now,
            "isUrl": false
        ]
        
        if let imageData = commentImageData {
            saveImageToStorage(key: key, imageData: imageData, onComplete: { (url) in
                commentAsDict["imageUrl"] = url
                commentRef.child(key).setValue(commentAsDict) { (error, ref) in
                    if let error = error {
                        onError(error.localizedDescription)
                        return
                    }
                    
                    self.updateArticleComment(articleId: articleId)
                    self.updateUserComment(articleId: articleId)
                    
                    onComplete()
                }
            }, onError: { (error) in
                onError(error)
            })
        } else {
            commentRef.child(key).setValue(commentAsDict) { (error, ref) in
                if let error = error {
                    onError(error.localizedDescription)
                    return
                }
                
                self.updateArticleComment(articleId: articleId)
                self.updateUserComment(articleId: articleId)
                
                onComplete()
            }
        }
    }
    
    func sendUrlComment(articleId: String, urlLink: String, urlTitle: String, urlImageUrl: String?, urlSource: String?) {
        let commentRef = self.database.reference(withPath: "comment/\(articleId)")
        
        let now = -floor(Double(Date().timeIntervalSince1970 * 1000))
        let key = commentRef.childByAutoId().key
        
        let commentAsDict: [String: Any?] = [
            "uid": uid,
            "userDisplayName": userDisplayName!,
            "commentText": urlTitle,
            "imageUrl": urlImageUrl,
            "pubDate": now,
            "isUrl": true,
            "urlSource": urlSource,
            "urlLink": urlLink
        ]
        
        commentRef.child(key).setValue(commentAsDict)
    }
    
    func updateArticleComment(articleId: String) {
        let query = articleRef.child(articleId)
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        var token: String = ""
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                
            } else if let result = result {
                token = result.token
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            query.runTransactionBlock({ (mutableData) -> TransactionResult in
                if var article = mutableData.value as? [String: Any] {
                    var commenters = article["commenters"] as? [String: Int] ?? [:]
                    var commentCount = article["commentCount"] as? Int ?? 0
                    var notificationTokens = article["notificationTokens"] as? [String: String] ?? [:]
                    
                    commenters[self.uid] = (commenters[self.uid] ?? 0) + 1
                    commentCount += 1
                    notificationTokens[self.uid] = token
                    
                    article["commenters"] = commenters as Any?
                    article["commentCount"] = commentCount as Any?
                    article["notificationTokens"] = notificationTokens as Any?
                    article["changedSinceLastJob"] = true as Any?
                    
                    mutableData.value = article
                    
                    return TransactionResult.success(withValue: mutableData)
                }
                return TransactionResult.success(withValue: mutableData)
            }, andCompletionBlock: { (error, committed, snap) in
                if let error = error {
                    
                }
                
            })
        }
    }
    
    func updateUserComment(articleId: String) {
        userRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            if var user = mutableData.value as? [String: Any] {
                var commentedItems = user["commentedItems"] as? [String: Int] ?? [:]
                var commentedItemsCount = user["commentedItemsCount"] as? Int ?? 0
                var points = user["points"] as? Double ?? 0
                
                commentedItemsCount = commentedItems.count + 1
                commentedItems[articleId] = commentedItemsCount
                points = points + 1
                
                user["commentedItems"] = commentedItems as Any?
                user["commentedItemsCount"] = commentedItemsCount as Any?
                user["points"] = points as Any?
                
                mutableData.value = user
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                
            }
            
        })
    }
    
    func reportComment(articleId: String, comment: Comment) {
        commentRef.child("\(articleId)/\(comment.commentId)/isReported").setValue(true)
        reportRef.child("comment/\(articleId)/\(comment.commentId)").setValue(comment.uid)
        
        let commenterUid = comment.uid
        let reportedUserRef = reportRef.child("user/\(commenterUid)")
        reportedUserRef.observeSingleEvent(of: .value) { (snap) in
            let count = snap.value as? Int ?? 0
            reportedUserRef.setValue(count + 1)
        }
    }
    
    
    // Post
    func createPost(post: Dictionary<String, Any?>, postImageData: Data?, onComplete: @escaping () -> (), onError: @escaping (String) -> ()) {
        var post = post
        
        if let imageData = postImageData {
            saveImageToStorage(key: post["objectID"] as! String, imageData: imageData, onComplete: { (url) in
                post["postImageUrl"] = url
                
                self.postRef.child(post["objectID"] as! String).setValue(post, withCompletionBlock: { (error, ref) in
                    if let error = error {
                        onError(error.localizedDescription)
                        return
                    }
                    
                    self.updateUserPost(post: post)
                    
                    onComplete()
                })
            }, onError: { (error) in
                onError(error)
            })
        } else {
            self.postRef.child(post["objectID"] as! String).setValue(post, withCompletionBlock: { (error, ref) in
                if let error = error {
                    onError(error.localizedDescription)
                    return
                }
                
                self.updateUserPost(post: post)
                
                onComplete()
            })
        }
    }
    
    func updateUserPost(post: Dictionary<String, Any?>) {
        userRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            if var user = mutableData.value as? [String: Any] {
                var createdPosts = user["createdPosts"] as? [String: Double] ?? [:]
                var createdPostsCount = user["createdPostsCount"] as? Int ?? 0
                var points = user["points"] as? Double ?? 0
                
                createdPosts[post["objectID"] as! String] = post["postDate"] as? Double
                createdPostsCount = createdPosts.count
                points = points + 1
                
                user["createdPosts"] = createdPosts as Any?
                user["createdPostsCount"] = createdPostsCount as Any?
                user["points"] = points as Any?
                
                mutableData.value = user
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                
            }
            
        })
    }
    
    
    // Storage
    private func saveImageToStorage(key: String, imageData: Data, onComplete: @escaping (String) -> (), onError: @escaping (String) -> ()) {
        var errorDescription: String?
        let imageStorageRef = userStorage.child("\(key).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageStorageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                errorDescription = error.localizedDescription
                onError(errorDescription!)
                return
            }
            
            imageStorageRef.downloadURL(completion: { (url, error) in
                if let error = error {
                    errorDescription = error.localizedDescription
                    onError(errorDescription!)
                    return
                }
                
                if let url = url {
                    onComplete(url.absoluteString)
                    return
                }
            })
        }
    }
    
    // Read time
    func setArticleReadTime(article: Article, readTime: Int) {
        let query = articleRef.child("\(article.objectID)/readTime")
        query.setValue(readTime)
    }
    
    // Settings
    func setCommentsNotificationPreference(bool: Bool) {
        if !bool {
            commentsPreferenceRef.setValue(bool)
        } else {
            commentsPreferenceRef.removeValue()
        }
    }
    
    func setRecArticlesNotificationPreference(bool: Bool) {
        if !bool {
            recArticlesPreferenceRef.setValue(bool)
        } else {
            recArticlesPreferenceRef.removeValue()
        }
    }
}
