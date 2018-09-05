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
    
    let algoliaClient = Client(appID: "O96PPLSF19", apiKey: "3b42d937aceab4818e2377325c76abf1")
    lazy var algoliaIndex = algoliaClient.index(withName: "article")
    
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
    
    lazy var userStorage = self.storage.reference(withPath: uid)
    
    var articleList = [Article]()
    var observedFeedQueries = [DatabaseQuery]()
    var observedArticlesQueries = [String: DatabaseQuery]()
    
    
    // Setup
    func getUser(onComplete: @escaping (AcornUser) -> ()) {
        userRef.observeSingleEvent(of: .value) { (snap) in
            let user = AcornUser(snapshot: snap)
            onComplete(user)
        }
    }
    
    func getThemeSubscriptions(user: User) {
        let uid = user.uid
        let subsRef = self.database.reference(withPath: "user/\(uid)/subscriptions")
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        subsRef.observeSingleEvent(of: .value) { (snap) in
            if let subs = snap.value as? [String] {
                let themePrefs = subs.sorted()
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
                dispatchGroup.leave()
            } else {
                self.defaults.set(nil, forKey: "themeFilters")
                self.defaults.set(nil, forKey: "themeKey")
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            print("themeKey: \(self.themeKey ?? "nil")")
            return
        }
    }
    
    func setThemeSubscriptions(_ themePrefs: [String]) {
        let subsRef = self.database.reference(withPath: "user/\(uid)/subscriptions")
        
        subsRef.setValue(themePrefs)
    }
    
    
    // Feed
    func observeArticles(query: DatabaseQuery, onComplete: @escaping ([Article]) -> ()) {
        var articles = [Article]()
        var articleIds = [String]()
        
        query.observe(.childAdded) { (snap) in
            print("articleID: \(snap.key)")
            if !articleIds.contains(snap.key) {
                articles.append(Article(snapshot: snap))
                print("articleLink: \(Article(snapshot: snap).link ?? "nil")")
                articleIds.append(snap.key)
            }
            onComplete(articles)
        }
        
        query.observe(.childChanged) { (snap) in
            if let index = articleIds.index(of: snap.key) {
                articles[index] = Article(snapshot: snap)
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
        if themeKey != nil {
            let hitsRef = searchRef.child(themeKey!).child("hits")
            let initQuery = searchRef.child(themeKey!).child("lastQueryTimestamp")
            initQuery.observeSingleEvent(of: .value) { (lastQuerySnap) in
                if let lastQueryTimestamp = lastQuerySnap.value as? Double {
                    let timeElapsed = DateUtils.hoursSince(unixTimestamp: lastQueryTimestamp)
                    if timeElapsed >= 3 {
                        print("getSubscriptionsFeed: new query: \(timeElapsed)")
                        let algoliaQuery = Query()
                        algoliaQuery.filters = self.themeFilters
                        self.algoliaIndex.search(algoliaQuery) { (content, error) in
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
                        print("getSubscriptionsFeed: last query within 3 hours: \(timeElapsed))")
                        let query = hitsRef.queryOrdered(byChild: "pubDate").queryLimited(toFirst: self.limit)
                        query.keepSynced(true)
                        self.observedFeedQueries.append(query)
                        self.observeArticles(query: query, onComplete: onComplete)
                    }
                } else {
                    print("getSubscriptionsFeed: themeKey not found")
                    let algoliaQuery = Query()
                    algoliaQuery.filters = self.themeFilters
                    self.algoliaIndex.search(algoliaQuery) { (content, error) in
                        if error == nil {
                            self.searchRef.child(self.themeKey!).setValue(content, withCompletionBlock: { (error, ref) in
                                initQuery.setValue(now)
                                let query = hitsRef.queryLimited(toFirst: self.limit)
                                query.keepSynced(true)
                                self.observedFeedQueries.append(query)
                                self.observeArticles(query: query, onComplete: onComplete)
                            })
                        }
                    }
                }
            }
        } else {
            print("getSubscriptionsFeed: no theme key")
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
    
    func observeSingleArticle(article: Article, onComplete: @escaping ((Article) -> ())) {
        let query = articleRef.child(article.objectID)
        query.observe(.value) { (snap) in
            onComplete(Article(snapshot: snap))
        }
        self.observedArticlesQueries[article.objectID] = query
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
        print("uid: \(uid)")
        let savedQuery = userRef.child("savedItems")
        savedQuery.observeSingleEvent(of: .value) { (savedSnap) in
            if let savedItems = savedSnap.value as? [String: Double] {
                for key in savedItems.keys {
                    print("savedItem key: \(key)")
                    savedList.append(key)
                }
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
            print("removed: \(query.ref.url)")
            query.removeAllObservers()
        }
        observedFeedQueries.removeAll()
    }
    
    func removeArticleObserver(article: Article) {
        if let query = observedArticlesQueries[article.objectID] {
            print("removed: \(query.ref.url)")
            query.removeAllObservers()
            observedArticlesQueries.removeValue(forKey: article.objectID)
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
                print(error.localizedDescription)
            }
            print("updateArticleVote: \(committed)")
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
                
                if actionIsUpvote {
                    upvotedItems[self.uid] = now
                    downvotedItems.removeValue(forKey: self.uid)
                } else {
                    upvotedItems.removeValue(forKey: self.uid)
                    downvotedItems[self.uid] = now
                }
                
                upvotedItemsCount = upvotedItems.count
                downvotedItemsCount = downvotedItems.count
                
                user["upvotedItems"] = upvotedItems as Any?
                user["downvotedItems"] = downvotedItems as Any?
                user["upvotedItemsCount"] = upvotedItemsCount as Any?
                user["downvotedItemsCount"] = downvotedItemsCount as Any?
                
                mutableData.value = user
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
            print("updateUserVote: \(committed)")
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
                print(error.localizedDescription)
            }
            print("updateArticleSave: \(committed)")
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
                print(error.localizedDescription)
            }
            print("updateUserSave: \(committed)")
            onComplete()
        })
    }
    
    
    // Comments
    func observeComments(query: DatabaseQuery, onComplete: @escaping ([Comment]) -> ()) {
        var comments = [Comment]()
        var commentIds = [String]()
        
        query.observe(.childAdded) { (snap) in
            if !commentIds.contains(snap.key) {
                comments.append(Comment(snapshot: snap))
                commentIds.append(snap.key)
            }
            onComplete(comments)
        }
        
        query.observe(.childChanged) { (snap) in
            if let index = commentIds.index(of: snap.key) {
                comments[index] = Comment(snapshot: snap)
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
    
    func getArticleComments(_ article: Article, onComplete: @escaping ([Comment]) -> ()) {
        let query = commentRef.child(article.objectID)
        observeComments(query: query, onComplete: onComplete)
    }
    
    func removeCommentObservers(_ article: Article) {
        commentRef.child(article.objectID).removeAllObservers()
    }
    
    func follow(article: Article) {
        var token: String?
        
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print(error)
            } else if let result = result {
                token = result.token
                let query = self.articleRef.child("\(article.objectID)/notificationTokens/\(self.uid)")
                query.setValue(token)
            }
        }
    }
    
    func unfollow(article: Article) {
        let query = self.articleRef.child("\(article.objectID)/notificationTokens/\(self.uid)")
        query.removeValue()
    }
    
    func sendComment(article: Article, commentText: String?, commentImageData: Data?, onComplete: @escaping () -> (), onError: @escaping (String) -> ()) {
        let commentRef = self.database.reference(withPath: "comment/\(article.objectID)")
        
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
                
                //updateCommentCount()
                //updateUserCommentCount()
                //updateNotificationTokens()
                //updateUserData(onComplete: pushUrlComment(commentRef, pubDate))
                
                onComplete()
            }
        }
    }
    
    func sendUrlComment(article: Article, urlLink: String, urlTitle: String, urlImageUrl: String?, urlSource: String?) {
        let commentRef = self.database.reference(withPath: "comment/\(article.objectID)")
        
        let now = -floor(Double(Date().timeIntervalSince1970 * 1000))
        let key = commentRef.childByAutoId().key
        
        let commentAsDict: [String: Any?] = [
            "commentId": key,
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
    
    func addArticleCommentCount(article: Article) {
        let ref = articleRef.child("\(article.objectID)/commentCount")
        
        ref.runTransactionBlock({ (mutableData) -> TransactionResult in
            if let commentCount = mutableData.value as? Int {
                mutableData.value = commentCount + 1
                return TransactionResult.success(withValue: mutableData)
            } else if mutableData.value == nil {
                mutableData.value = 1
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
        })
    }
    
    func addArticleCommenters(article: Article) {
        let ref = articleRef.child("\(article.objectID)/commenters/\(uid)")
        
        ref.runTransactionBlock({ (mutableData) -> TransactionResult in
            if let commentCount = mutableData.value as? Int {
                mutableData.value = commentCount + 1
                return TransactionResult.success(withValue: mutableData)
            } else if mutableData.value == nil {
                mutableData.value = 1
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
        })
    }
    
    func addArticleNotificationTokens(article: Article, token: String) {
        let ref = articleRef.child("\(article.objectID)/notificationTokens/\(uid)")
        
        ref.runTransactionBlock({ (mutableData) -> TransactionResult in
            if let _ = mutableData.value as? String {
                mutableData.value = token
                return TransactionResult.success(withValue: mutableData)
            } else if mutableData.value == nil {
                mutableData.value = token
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
        })
    }
    
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
                
                onComplete()
            })
        }
    }
    
    func updateUserPost(post: Article) {
        userRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            if var user = mutableData.value as? [String: Any] {
                var createdPosts = user["createdPosts"] as? [String: Double] ?? [:]
                var createdPostsCount = user["createdPostsCount"] as? Int ?? 0
                
                createdPosts[post.objectID] = post.postDate
                createdPostsCount = createdPosts.count
                
                user["createdPosts"] = createdPosts as Any?
                user["createdPostsCount"] = createdPostsCount as Any?
                
                mutableData.value = user
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
            print("updateUserPost: \(committed)")
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
}
