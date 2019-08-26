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
import S2GeometrySwift

class DataSource {
    
    static let instance = DataSource()
    
    var algoliaApiKey: String?
    var algoliaClient: Client?
    var algoliaIndex: Index?
    
    let limit = 100 as UInt
    
    let defaults = UserDefaults.standard
    var themeKey: String?
    var themeFilters: String?
    
    lazy var database = Database.database()
    lazy var storage = Storage.storage()
    
    lazy var user = Auth.auth().currentUser!
    lazy var uid = user.uid
    lazy var userDisplayName = user.displayName
    
    lazy var articleRef = self.database.reference(withPath: "article")
    lazy var videoRef = self.database.reference(withPath: "video")
    lazy var searchRef = self.database.reference(withPath: "search")
    lazy var commentRef = self.database.reference(withPath: "comment")
    lazy var userRef = self.database.reference(withPath: "user/\(uid)")
    lazy var postRef = self.database.reference(withPath: "article")
    lazy var addressRef = self.database.reference(withPath: "address")
    lazy var commentsPreferenceRef = self.database.reference(withPath: "preference/commentsNotificationValue/\(uid)")
    lazy var recArticlesPreferenceRef = self.database.reference(withPath: "preference/recArticlesNotificationValue/\(uid)")
    lazy var recDealsPreferenceRef = self.database.reference(withPath: "preference/recDealsNotificationValue/\(uid)")
    lazy var savedArticlesReminderPreferenceRef = self.database.reference(withPath: "preference/savedArticlesReminderNotificationValue/\(uid)")
    lazy var locationPreferenceRef = self.database.reference(withPath: "preference/locationNotificationValue/\(uid)")
    lazy var videosInFeedPreferenceRef = self.database.reference(withPath: "preference/videosInFeed/\(uid)")
    lazy var algoliaRef = self.database.reference(withPath: "api/algoliaKey")
    lazy var youtubeApiRef = self.database.reference(withPath: "api/youtubeKey")
    lazy var reportRef = self.database.reference(withPath: "reported")
    lazy var notificationRef = self.database.reference(withPath: "notification")
    lazy var timeLogRef = self.database.reference(withPath: "timeLog")
    lazy var surveyRef = self.database.reference(withPath: "survey")
    
    lazy var userStorage = self.storage.reference(withPath: uid)
    
    var articleList = [Article]()
    var observedFeedQueries = [DatabaseQuery]()
    var observedArticlesQueries = [String: DatabaseQuery]()
    var observedVideosQueries = [String: DatabaseQuery]()
    
    let TARGET_POINTS_MULTIPLIER = 3.0
    let LEVEL_0 = "Budding Seed"
    let LEVEL_1 = "Emerging Sprout"
    let LEVEL_2 = "Thriving Sapling"
    let LEVEL_3 = "Wise Oak"
    var userStatus: String?
    
    
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
    
    func getYouTubeApi(onComplete: @escaping (String) -> ()) {
        youtubeApiRef.observeSingleEvent(of: .value) { (snap) in
            guard let apiKey = snap.value as? String else { return }
            
            onComplete(apiKey)
        }
    }
    
    func getUser(user: User, onComplete: @escaping (AcornUser?) -> ()) {
        let userRef = self.database.reference(withPath: "user/\(user.uid)")
        userRef.observeSingleEvent(of: .value) { (snap) in
            if let user = snap.value as? [String: Any] {
                if user["uid"] != nil {
                    let user = AcornUser(snapshot: snap)
                    print("user: \(user.displayName)")
                    onComplete(user)
                } else {
                    print("no user uid")
                    onComplete(nil)
                }
            } else {
                print("no user data")
                onComplete(nil)
            }
        }
    }
    
    func removeAllListenersOnUser(user: User) {
        self.userRef.removeAllObservers()
    }
    
    func setUser(_ user: [String: Any?]) {
        self.userRef.setValue(user)
    }
    
    func updateUser(_ user: [String: Any?]) {
        self.userRef.updateChildValues(user as [AnyHashable : Any])
    }
    
    func getUserStatus(_ status: Int) -> String {
        switch status {
        case 0: return self.LEVEL_0
        case 1: return self.LEVEL_1
        case 2: return self.LEVEL_2
        case 3: return self.LEVEL_3
        default: return self.LEVEL_0
        }
    }
    
    func getUserPremiumStatus(_ user: User, onComplete: @escaping ([String: Double]) -> ()) {
        let userRef = self.database.reference(withPath: "user/\(user.uid)")
        userRef.child("premiumStatus").observe(.value) { (snap) in
            if let status = snap.value as? [String: Double] {
                onComplete(status)
            }
        }
    }
    
    func removePremiumStatusObserver() {
        self.userRef.child("premiumStatus").removeAllObservers()
    }
    
    func getThemeSubscriptions(user: User, onComplete: (([String]) -> ())?) {
        let uid = user.uid
        let subsRef = self.database.reference(withPath: "user/\(uid)/subscriptions")
//        subsRef.keepSynced(true);
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
    func observeSingleArticle(articleId: String, onComplete: @escaping ((Article) -> ())) {
        let query = articleRef.child(articleId)
        query.observe(.value) { (snap) in
            if let _ = snap.value {
                let article = Article(snapshot: snap)
                onComplete(article)
            }
        }
        self.observedArticlesQueries[articleId] = query
    }
    
    func observeArticles(query: DatabaseQuery, onComplete: @escaping ([Article]) -> ()) {
        var articles = [Article]()
        var articleIds = [String]()
        
        query.observe(.childAdded) { (snap) in
            guard let _ = snap.value else { return }
            let article = Article(snapshot: snap)
            
            if !articleIds.contains(snap.key) {
                let isReported = article.isReported ?? false
                if !isReported {
                    articles.append(article)
                    articleIds.append(snap.key)
                }
//                print("articles: \(articles.count), articleId: \(article.objectID)");
            }
            onComplete(articles)
        }
        
        query.observe(.childChanged) { (snap) in
            let article = Article(snapshot: snap)
            
            if let index = articleIds.firstIndex(of: snap.key) {
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
            if let index = articleIds.firstIndex(of: snap.key) {
                articles.remove(at: index)
                articleIds.remove(at: index)
            }
            onComplete(articles)
        }
        
        query.observe(.childMoved) { (snap, previousChildKey) in
            if let index = articleIds.firstIndex(of: snap.key) {
                articleIds.remove(at: index)
                articles.remove(at: index)
            }
            let newIndex = (previousChildKey != nil) ? articleIds.firstIndex(of: previousChildKey!)! + 1 : 0
            articleIds.insert(snap.key, at: newIndex)
            articles.insert(Article(snapshot: snap), at: newIndex)
            onComplete(articles)
        }
    }
    
    func observeHitsArticles(query: DatabaseQuery, limit: UInt, onComplete: @escaping ([Article]) -> ()) {
        var articles = [Article]()
        var articleIds = [String]()
        var duplicatesIds = [String]()
        
        query.observe(.value) { (snap) in
            // if value changes, reset all articles and remove all observers
            if articleIds.count > 0 {
                for articleId in articleIds {
                    self.articleRef.child(articleId).removeAllObservers()
                }
                articles.removeAll()
                articleIds.removeAll()
                duplicatesIds.removeAll()
            }
            
            guard let _ = snap.value else { return }
            var count = 0
            for case let data as DataSnapshot in snap.children {
                let hitsArticle = Article(snapshot: data)
                self.articleRef.child(hitsArticle.objectID).observeSingleEvent(of: .value) { (articleSnap) in
                    count += 1
                    if let _ = articleSnap.value {
                        let article = Article(snapshot: articleSnap)
                        
                        if !articleIds.contains(article.objectID) {
                            let isReported = article.isReported ?? false
                            if !isReported && !duplicatesIds.contains(article.objectID) {
                                articles.append(article)
                                articleIds.append(article.objectID)
                                if let duplicates = article.duplicates {
                                    duplicatesIds.append(contentsOf: Array(duplicates.keys))
                                }
                            }
                        } else {
                            if let index = articleIds.firstIndex(of: article.objectID) {
                                let isReported = article.isReported ?? false
                                if isReported {
                                    self.articleRef.child(article.objectID).removeAllObservers()
                                    articles.remove(at: index)
                                    articleIds.remove(at: index)
                                    if let duplicates = article.duplicates {
                                        for duplicateId in duplicates.keys {
                                            if let duplicateIndex = duplicatesIds.firstIndex(of: duplicateId) {
                                                duplicatesIds.remove(at: duplicateIndex)
                                            }
                                        }
                                    }
                                } else {
                                    articles[index] = article
                                }
                            }
                        }
                    } else {
                        if let index = articleIds.firstIndex(of: articleSnap.key) {
                            self.articleRef.child(articleSnap.key).removeAllObservers()
                            articleIds.remove(at: index)
                            articles.remove(at: index)
                        }
                    }
                    if (count == limit) { onComplete(articles) }
                }
            }
        }
    }
    
    func getAlgoliaHitsData(key: String?, filters: String?, onComplete: @escaping ([Article]) -> ()) {
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        setupAlgoliaClient {
            if key != nil {
                let hitsRef = self.searchRef.child(key!).child("hits")
//                hitsRef.keepSynced(true);
                let initQuery = self.searchRef.child(key!).child("lastQueryTimestamp")
                initQuery.observeSingleEvent(of: .value) { (lastQuerySnap) in
                    if let lastQueryTimestamp = lastQuerySnap.value as? Double {
                        let timeElapsed = DateUtils.hoursSince(unixTimestamp: lastQueryTimestamp)
                        if timeElapsed >= 1 { // 1 hour since last load
                            let algoliaQuery = Query()
                            algoliaQuery.filters = filters
                            self.algoliaIndex?.search(algoliaQuery) { (content, error) in
                                if error == nil {
                                    self.searchRef.child(key!).setValue(content, withCompletionBlock: { (error, ref) in
                                        initQuery.setValue(now)
                                        let query = hitsRef.queryOrdered(byChild: "trendingIndex").queryLimited(toFirst: self.limit)
//                                        query.keepSynced(true)
                                        self.observedFeedQueries.append(query)
                                        self.observeHitsArticles(query: query, limit: self.limit, onComplete: onComplete)
                                    })
                                }
                            }
                        } else {
                            let query = hitsRef.queryOrdered(byChild: "trendingIndex").queryLimited(toFirst: self.limit)
//                            query.keepSynced(true)
                            self.observedFeedQueries.append(query)
                            self.observeHitsArticles(query: query, limit: self.limit, onComplete: onComplete)
                        }
                    } else {
                        let algoliaQuery = Query()
                        algoliaQuery.filters = filters
                        self.algoliaIndex?.search(algoliaQuery) { (content, error) in
                            if error == nil {
                                self.searchRef.child(key!).setValue(content, withCompletionBlock: { (error, ref) in
                                    initQuery.setValue(now)
                                    let query = hitsRef.queryOrdered(byChild: "trendingIndex").queryLimited(toFirst: self.limit)
//                                    query.keepSynced(true)
                                    self.observedFeedQueries.append(query)
                                    self.observeHitsArticles(query: query, limit: self.limit, onComplete: onComplete)
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getAlgoliaHitsData(key: String?, filters: String?, limit: UInt?, onComplete: @escaping ([Article]) -> ()) {
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        setupAlgoliaClient {
            if key != nil {
                let hitsRef = self.searchRef.child(key!).child("hits")
//                hitsRef.keepSynced(true);
                let initQuery = self.searchRef.child(key!).child("lastQueryTimestamp")
                initQuery.observeSingleEvent(of: .value) { (lastQuerySnap) in
                    if let lastQueryTimestamp = lastQuerySnap.value as? Double {
                        let timeElapsed = DateUtils.hoursSince(unixTimestamp: lastQueryTimestamp)
                        if timeElapsed >= 3 {
                            
                            let algoliaQuery = Query()
                            algoliaQuery.filters = filters
                            self.algoliaIndex?.search(algoliaQuery) { (content, error) in
                                if error == nil {
                                    self.searchRef.child(key!).setValue(content, withCompletionBlock: { (error, ref) in
                                        initQuery.setValue(now)
                                        let query = hitsRef.queryOrdered(byChild: "trendingIndex").queryLimited(toFirst: limit ?? self.limit)
//                                        query.keepSynced(true)
                                        self.observedFeedQueries.append(query)
                                        self.observeHitsArticles(query: query, limit: self.limit, onComplete: onComplete)
                                    })
                                }
                            }
                        } else {
                            
                            let query = hitsRef.queryOrdered(byChild: "trendingIndex").queryLimited(toFirst: self.limit)
//                            query.keepSynced(true)
                            self.observedFeedQueries.append(query)
                            self.observeHitsArticles(query: query, limit: self.limit, onComplete: onComplete)
                        }
                    } else {
                        
                        let algoliaQuery = Query()
                        algoliaQuery.filters = filters
                        self.algoliaIndex?.search(algoliaQuery) { (content, error) in
                            if error == nil {
                                self.searchRef.child(key!).setValue(content, withCompletionBlock: { (error, ref) in
                                    initQuery.setValue(now)
                                    let query = hitsRef.queryOrdered(byChild: "trendingIndex").queryLimited(toFirst: self.limit)
//                                    query.keepSynced(true)
                                    self.observedFeedQueries.append(query)
                                    self.observeHitsArticles(query: query, limit: self.limit, onComplete: onComplete)
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getSubscriptionsFeed(onComplete: @escaping ([Article]) -> ()) {
        themeKey = defaults.string(forKey: "themeKey")
        themeFilters = defaults.string(forKey: "themeFilters")
        getAlgoliaHitsData(key: themeKey, filters: themeFilters, onComplete: onComplete)
    }
    
    func getSubscriptionsFeed(startAt: String, onComplete: @escaping ([Article]) -> ()) {
        themeKey = defaults.string(forKey: "themeKey")
        let hitsRef = searchRef.child(themeKey!).child("hits")
        let query = hitsRef.queryOrdered(byChild: "trendingIndex").queryLimited(toFirst: self.limit + 1).queryStarting(atValue: startAt)
//        query.keepSynced(true)
        self.observedFeedQueries.append(query)
        self.observeArticles(query: query, onComplete: onComplete)
    }
    
    func getRecentFeed(onComplete: @escaping ([Article]) -> ()) {
        let query = articleRef.queryOrdered(byChild: "pubDate").queryLimited(toFirst: self.limit)
//        query.keepSynced(true)
        observedFeedQueries.append(query)
        observeArticles(query: query, onComplete: onComplete)
    }
    
    func getRecentFeed(startAt: Double, onComplete: @escaping ([Article]) -> ()) {
        let query = articleRef.queryOrdered(byChild: "pubDate").queryLimited(toFirst: self.limit + 1).queryStarting(atValue: startAt)
//        query.keepSynced(true)
        observedFeedQueries.append(query)
        observeArticles(query: query, onComplete: onComplete)
    }
    
    func getTrendingFeed(onComplete: @escaping ([Article]) -> ()) {
        themeKey = ResourcesDay.THEME_LIST.joined(separator: "_")
        themeFilters = "mainTheme: \"" + ResourcesDay.THEME_LIST.joined(separator: "\" OR mainTheme: \"") + "\""
        getAlgoliaHitsData(key: themeKey, filters: themeFilters, onComplete: onComplete)
    }
    
    func getTrendingFeed(startAt: String, onComplete: @escaping ([Article]) -> ()) {
        themeKey = ResourcesDay.THEME_LIST.joined(separator: "_")
        let hitsRef = searchRef.child(themeKey!).child("hits")
        let query = hitsRef.queryOrdered(byChild: "trendingIndex").queryLimited(toFirst: self.limit + 1).queryStarting(atValue: startAt)
//        query.keepSynced(true)
        self.observedFeedQueries.append(query)
        self.observeArticles(query: query, onComplete: onComplete)
    }
    
    func downloadSubscribedArticles(onComplete: @escaping () -> ()) {
        let localDb = LocalDb.instance
        themeKey = defaults.string(forKey: "themeKey")
        themeFilters = defaults.string(forKey: "themeFilters")
        getAlgoliaHitsData(key: themeKey, filters: themeFilters, limit: 100) { (articleList) in
            if (articleList.count == 100) {
                for article in articleList {
                    if article.type == "article" {
                        article.htmlContent = HtmlUtils().cleanHtmlContent(html: article.htmlContent ?? "", link: article.link ?? "", selector: article.selector, aid: article.objectID)
                        let localArticle = dbArticle(uid: self.uid, article: article)
                        localDb.insertArticle(localArticle)
                    }
                }
                onComplete()
            }
        }
    }
    
    func getDealsFeed(onComplete: @escaping ([Article]) -> ()) {
        let dealsKey = "Deals"
        let dealsFilter = "mainTheme: Deals"
        getAlgoliaHitsData(key: dealsKey, filters: dealsFilter, onComplete: onComplete)
    }
    
    func getDealsFeed(startAt: String, onComplete: @escaping ([Article]) -> ()) {
        let dealsKey = "Deals"
        let hitsRef = searchRef.child(dealsKey).child("hits")
        let query = hitsRef.queryOrdered(byChild: "trendingIndex").queryLimited(toFirst: self.limit + 1).queryStarting(atValue: startAt)
//        query.keepSynced(true)
        self.observedFeedQueries.append(query)
        self.observeArticles(query: query, onComplete: onComplete)
    }
    
    func getSavedFeed(onComplete: @escaping ([Article]) -> ()) {
        getSavedFeed(startAt: 0, limit: 200, onComplete: onComplete)
    }
    
    func getSavedFeed(startAt: Int, limit: UInt, onComplete: @escaping ([Article]) -> ()) {
        var savedList = [String]()
        var articles = [Article]()
        
        let savedQuery = userRef.child("savedItems")
//        savedQuery.keepSynced(true);
        savedQuery.observeSingleEvent(of: .value) { (savedSnap) in
            if let savedItems = savedSnap.value as? [String: Double] {
                savedList.append(contentsOf: savedItems.keys)
                if savedList.count == 0 { return }
                var counter = startAt
                let endIndex = min(startAt + Int(limit), savedList.count)
                for saved in savedList[startAt ..< endIndex] {
                    let query = self.articleRef.child(saved)
//                    query.keepSynced(true)
                    self.observedFeedQueries.append(query)
                    query.observe(.value, with: { (articleSnap) in
                        counter += 1
                        if let _ = articleSnap.value as? [String: Any] {
                            articles.append(Article(snapshot: articleSnap))
                        }
                        if (counter == savedList.count || counter == limit) {
                            onComplete(articles)
                        }
                    })
                }
            }
        }
    }
    
    func getFilteredThemeFeed(key: String?, filters: String?, onComplete: @escaping ([Article]) -> ()) {
        guard let key = key, let filters = filters else { return }
        getAlgoliaHitsData(key: key, filters: filters, onComplete: onComplete)
    }
    
    func getFilteredThemeFeed(startAt: String, key: String?, onComplete: @escaping ([Article]) -> ()) {
        guard let key = key else { return }
        let hitsRef = searchRef.child(key).child("hits")
        let query = hitsRef.queryOrdered(byChild: "trendingIndex").queryLimited(toFirst: self.limit + 1).queryStarting(atValue: startAt)
//        query.keepSynced(true)
        self.observedFeedQueries.append(query)
        self.observeArticles(query: query, onComplete: onComplete)
    }
    
    func getNearbyFeed(lat: Double, lng: Double, radius: Double, keyword: String? = nil, weekOnly: Bool = false, limit: Int = 50, onComplete: @escaping ([Article]) -> ()) {
        // get sphere cap centred at location
        let point: S2Point = S2LatLng.fromDegrees(lat: lat, lng: lng).point
        let angle: S1Angle = S1Angle.init(radians: radius / S2LatLng.earthRadiusMeters)
        let cap: S2Cap = S2Cap.init(axis: point, angle: angle)
        
        // get covering cell ids
        let coverer: S2RegionCoverer = S2RegionCoverer.init()
        coverer.maxCells = 5
        let covering = coverer.getInteriorCovering(region: cap)
        
        // get all addresses and associated articles in covering cells
        var articleIds = [String: Double]()
        var postcodeList = [String: [String]]()
        let dispatchGroup = DispatchGroup()
        for id in covering {
            dispatchGroup.enter()
            let minRange = String(id.rangeMin.id)
            let maxRange = String(id.rangeMax.id)
            print("minRange: " + minRange + ", maxRange: " + maxRange)
            let addressQuery = self.addressRef.queryOrderedByKey().queryStarting(atValue: minRange).queryEnding(atValue: maxRange)
            
            addressQuery.observeSingleEvent(of: .value) { (snap) in
                for case let data as DataSnapshot in snap.children {
                    let address = Address(snapshot: data)
                    let postcodePattern = try? NSRegularExpression(pattern:".*(Singapore [0-9]{6})", options: .caseInsensitive)
                    let postcode = postcodePattern?.stringByReplacingMatches(in: address.address, options: [], range: NSMakeRange(0, address.address.count), withTemplate: "$1")
                    for articleId in address.article.keys {
                        if let reminderDate = address.article[articleId] {
                            let cutoff = DateUtils.getFourteenDaysAgoMidnight()
                            if (reminderDate > cutoff || reminderDate == 1) {
                                /*
                                 these are all the articles with no reminderDate or reminderDate more than 14 days ago, i.e. first date appearing in title is more than 14 days ago. this is so we avoid removing articles with dates from x to y where reminder date is x-1 but event is still valid as y has not reached. the implication is that there will be deals/events that expired up to 14 days ago
                                */
                                articleIds[articleId] = reminderDate
                                if let postcode = postcode {
                                    var currentList = [postcode]
                                    if let list = postcodeList[articleId] {
                                        currentList.append(contentsOf: list)
                                    }
                                    postcodeList[articleId] = currentList
                                }
                            } else {
                                print("addressId: \(address.objectID), reminderDate: \(reminderDate)")
                                self.addressRef.child(address.objectID).child("article").child(articleId).removeValue()
                            }
                        }
                    }
                }
                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("articleIds size: \(articleIds.count)")
            print("postcodeList size: \(postcodeList.count)")
            self.filterNearbyArticles(articleIds: articleIds, postcodeList: postcodeList, keyword: keyword, weekOnly: weekOnly, limit: limit, onComplete: { (articles) in
                onComplete(articles)
            })
        }
    }
    
    func filterNearbyArticles(articleIds: [String: Double], postcodeList: [String: [String]], keyword: String? = nil, weekOnly: Bool = false, limit: Int = 50, onComplete: @escaping ([Article]) -> ()) {
        if articleIds.count == 0 {
            onComplete([Article]())
            return
        }
        
        var articles = [Article]()
        
        var datedArticleIds = [String: Double]()
        var undatedArticleIds = [String]()
        for entry in articleIds {
            if entry.value > 1 {
                let now = Date().timeIntervalSince1970 * 1000
                let absDiff = abs(now - entry.value)
                if weekOnly {
                    let weekAgoMidnight = DateUtils.getWeekAgoMidnight()
                    let weekLaterMidnight = DateUtils.getWeekLaterMidnight()
                    if (entry.value >= weekAgoMidnight && entry.value < weekLaterMidnight) {
                        datedArticleIds[entry.key] = absDiff
                    }
                } else {
                    datedArticleIds[entry.key] = absDiff
                }
            } else {
                undatedArticleIds.append(entry.key)
            }
        }
        
        // sort datedArticleIds by proximity to today
        let sortedDatedArticles = Array(datedArticleIds.keys).sorted(by: { datedArticleIds[$0]! < datedArticleIds[$1]! })
        
        // dated articles will go on top, undated articles will be randomised
        let articleIdList = sortedDatedArticles + undatedArticleIds.shuffled()
        
        let articleLimit = min(limit, articleIdList.count)
        let dispatchGroup = DispatchGroup()
        if let keyword = keyword {
            var doneList = [String: Bool]()
            var rejectList = [String: Bool]()
            for articleId in articleIdList {
                if doneList.count >= articleLimit {
                    break
                }
                
                let query = self.articleRef.child(articleId)
                query.observeSingleEvent(of: .value) { (snap) in
                    let article = Article(snapshot: snap)
                    if article.title?.range(of: keyword, options: .caseInsensitive) != nil ||
                        article.mainTheme?.range(of: keyword, options: .caseInsensitive) != nil ||
                        article.source?.range(of: keyword, options: .caseInsensitive) != nil ||
                        article.postAuthor?.range(of: keyword, options: .caseInsensitive) != nil ||
                        article.postText?.range(of: keyword, options: .caseInsensitive) != nil {
                        article.postcode = Array(Set(postcodeList[articleId] ?? [String]()))
                        articles.append(article)
                        doneList[articleId] = true
                    } else {
                        rejectList[articleId] = false
                    }
                    
                    if (doneList.count >= articleLimit || doneList.count + rejectList.count >= articleIdList.count) {
                        onComplete(articles)
                    }
                }
            }
        } else {
            for index in 0..<articleLimit {
                let articleId = articleIdList[index]
                let query = self.articleRef.child(articleId)
                dispatchGroup.enter()
                query.observeSingleEvent(of: .value) { (snap) in
                    let article = Article(snapshot: snap)
                    article.postcode = postcodeList[articleId]
                    articles.append(article)
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                onComplete(articles)
            }
        }
    }
    
    func getMrtStationByName(locale: String, onComplete: @escaping ([String: [String: Any]]) -> ()) {
        let name = locale + " MRT Station"
        var mrtStationMap = [String: [String: Any]]()
        let mrtQuery = database.reference(withPath: "mrtStation").queryOrdered(byChild: "stationName").queryEqual(toValue: name)
        mrtQuery.observeSingleEvent(of: .value) { (snap) in
            for case let data as DataSnapshot in snap.children {
                let station = MrtStation(snapshot: data)
                if let locale = station.stationLocale {
                    if (mrtStationMap[locale] == nil) {
                        var location = [String: Any]()
                        location["latitude"] = station.latitude
                        location["longitude"] = station.longitude
                        location["geofence"] = station.geofence
                        mrtStationMap[locale] = location
                    }
                }
            }
            onComplete(mrtStationMap)
        }
    }
    
    func getMrtStations(onComplete: @escaping ([String: [String: Any]]) -> ()) {
        var mrtStationMap = [String: [String: Any]]()
        let mrtQuery = database.reference(withPath: "mrtStation").queryOrdered(byChild: "type").queryEqual(toValue: "MRT")
        mrtQuery.observeSingleEvent(of: .value) { (snap) in
            for case let data as DataSnapshot in snap.children {
                let station = MrtStation(snapshot: data)
                if let locale = station.stationLocale {
                    if (mrtStationMap[locale] == nil) {
                        var location = [String: Any]()
                        location["latitude"] = station.latitude
                        location["longitude"] = station.longitude
                        location["geofence"] = station.geofence
                        mrtStationMap[locale] = location
                    }
                }
            }
            onComplete(mrtStationMap)
        }
    }
    
    func removeFeedObservers() {
        for query in observedFeedQueries {
            query.removeAllObservers()
        }
        observedFeedQueries.removeAll()
    }
    
    func removeArticleObserver(_ articleId: String) {
        if let _ = observedArticlesQueries[articleId] {
            self.articleRef.child(articleId).removeAllObservers()
            observedArticlesQueries.removeValue(forKey: articleId)
        }
    }
    
    func removeVideoObserver(_ videoId: String) {
        if let _ = observedVideosQueries[videoId] {
            self.videoRef.child(videoId).removeAllObservers()
            observedVideosQueries.removeValue(forKey: videoId)
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
        let limit = 1
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
                                        let query = hitsRef.queryLimited(toFirst: UInt(limit))
                                        var articles = [Article]()
                                        query.observe(.childAdded, with: { (snap) in
                                            let article = Article(snapshot: snap)
                                            articles.append(article)
                                            if articles.count == limit {
                                                hitsRef.removeAllObservers()
                                                onComplete(articles)
                                            }
                                        })
                                    })
                                }
                            }
                        } else {
                            
                            let query = hitsRef.queryLimited(toFirst: UInt(limit))
                            var articles = [Article]()
                            query.observe(.childAdded, with: { (snap) in
                                let article = Article(snapshot: snap)
                                articles.append(article)
                                
                                if articles.count == limit {
                                    hitsRef.removeAllObservers()
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
                                    let query = hitsRef.queryLimited(toFirst: UInt(limit))
                                    var articles = [Article]()
                                    query.observe(.childAdded, with: { (snap) in
                                        let article = Article(snapshot: snap)
                                        articles.append(article)
                                        if articles.count == limit {
                                            hitsRef.removeAllObservers()
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
    
    
    // Recommended Deals
    func getRecommendedDeals(onComplete: @escaping ([Article]) -> ()) {
        let limit = 1
        let dealsKey = "Deals"
        let dealsFilter = "mainTheme: Deals"
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        setupAlgoliaClient {
            if self.themeKey != nil {
                let hitsRef = self.searchRef.child(dealsKey).child("hits")
                let initQuery = self.searchRef.child(dealsKey).child("lastQueryTimestamp")
                initQuery.observeSingleEvent(of: .value) { (lastQuerySnap) in
                    if let lastQueryTimestamp = lastQuerySnap.value as? Double {
                        let timeElapsed = DateUtils.hoursSince(unixTimestamp: lastQueryTimestamp)
                        if timeElapsed >= 3 {
                            
                            let algoliaQuery = Query()
                            algoliaQuery.filters = dealsFilter
                            self.algoliaIndex?.search(algoliaQuery) { (content, error) in
                                if error == nil {
                                    self.searchRef.child(dealsKey).setValue(content, withCompletionBlock: { (error, ref) in
                                        initQuery.setValue(now)
                                        let query = hitsRef.queryLimited(toFirst: UInt(limit))
                                        var articles = [Article]()
                                        query.observe(.childAdded, with: { (snap) in
                                            let article = Article(snapshot: snap)
                                            articles.append(article)
                                            if articles.count == limit {
                                                hitsRef.removeAllObservers()
                                                onComplete(articles)
                                            }
                                        })
                                    })
                                }
                            }
                        } else {
                            
                            let query = hitsRef.queryLimited(toFirst: UInt(limit))
                            var articles = [Article]()
                            query.observe(.childAdded, with: { (snap) in
                                let article = Article(snapshot: snap)
                                articles.append(article)
                                
                                if articles.count == limit {
                                    hitsRef.removeAllObservers()
                                    onComplete(articles)
                                }
                            })
                        }
                    } else {
                        
                        let algoliaQuery = Query()
                        algoliaQuery.filters = dealsFilter
                        self.algoliaIndex?.search(algoliaQuery) { (content, error) in
                            if error == nil {
                                self.searchRef.child(dealsKey).setValue(content, withCompletionBlock: { (error, ref) in
                                    initQuery.setValue(now)
                                    let query = hitsRef.queryLimited(toFirst: UInt(limit))
                                    var articles = [Article]()
                                    query.observe(.childAdded, with: { (snap) in
                                        let article = Article(snapshot: snap)
                                        articles.append(article)
                                        if articles.count == limit {
                                            hitsRef.removeAllObservers()
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
    
    // Saved articles reminder
    func getSavedArticlesReminderData(onComplete: @escaping ([Article]) -> ()) {
        var reminderList = [Article]()
        self.userRef.child("savedItems").observeSingleEvent(of: .value) { (snap) in
            if let savedItems = snap.value as? [String: Double] {
                var doneList = [String]()
                for id in savedItems.keys {
                    self.articleRef.child(id).observeSingleEvent(of: .value) { (articleSnap) in
                        doneList.append(id)
                        let article = Article(snapshot: articleSnap)
                        if let reminderDate = article.reminderDate {
                            if (reminderDate > DateUtils.getThisMidnight() && reminderDate < DateUtils.getNextMidnight()) {
                                reminderList.append(article)
                            }
                            
                            if doneList.count >= savedItems.count {
                                onComplete(reminderList)
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
                    Analytics.logEvent("upvote_article", parameters: [
                        AnalyticsParameterItemID: article["objectID"] ?? "",
                        AnalyticsParameterItemCategory: article["mainTheme"] ?? "",
                        "item_source": article["source"] ?? "",
                        AnalyticsParameterContentType: article["type"] ?? ""
                    ])
                    upvoters[self.uid] = now
                    downvoters.removeValue(forKey: self.uid)
                } else if (actionIsUpvote && !wasUpvoted && !wasDownvoted) {
                    Analytics.logEvent("upvote_article", parameters: [
                        AnalyticsParameterItemID: article["objectID"] ?? "",
                        AnalyticsParameterItemCategory: article["mainTheme"] ?? "",
                        "item_source": article["source"] ?? "",
                        AnalyticsParameterContentType: article["type"] ?? ""
                    ])
                    upvoters[self.uid] = now
                } else if (!actionIsUpvote && wasUpvoted) {
                    upvoters.removeValue(forKey: self.uid)
                    Analytics.logEvent("downvote_article", parameters: [
                        AnalyticsParameterItemID: article["objectID"] ?? "",
                        AnalyticsParameterItemCategory: article["mainTheme"] ?? "",
                        "item_source": article["source"] ?? "",
                        AnalyticsParameterContentType: article["type"] ?? ""
                    ])
                    downvoters[self.uid] = now
                } else if (!actionIsUpvote && wasDownvoted) {
                    downvoters.removeValue(forKey: self.uid)
                } else if (!actionIsUpvote && !wasUpvoted && !wasDownvoted) {
                    Analytics.logEvent("downvote_article", parameters: [
                        AnalyticsParameterItemID: article["objectID"] ?? "",
                        AnalyticsParameterItemCategory: article["mainTheme"] ?? "",
                        "item_source": article["source"] ?? "",
                        AnalyticsParameterContentType: article["type"] ?? ""
                    ])
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
            
            onComplete()
        })
    }
    
    func updateUserVote(article: Article, actionIsUpvote: Bool, onComplete: @escaping (String?) -> ()) {
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        
        userRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            if var user = mutableData.value as? [String: Any] {
                var upvotedItems = user["upvotedItems"] as? [String: Double] ?? [:]
                var downvotedItems = user["downvotedItems"] as? [String: Double] ?? [:]
                var upvotedItemsCount = user["upvotedItemsCount"] as? Int ?? 0
                var downvotedItemsCount = user["downvotedItemsCount"] as? Int ?? 0
                var points = user["points"] as? Double ?? 0
                var targetPoints = user["targetPoints"] as? Double ?? 0
                var status = user["status"] as? Int ?? 0
                
                if actionIsUpvote {
                    // upvote clicked
                    if let _ = upvotedItems[article.objectID] {
                        // previously upvoted
                        upvotedItems.removeValue(forKey: article.objectID)
                        points -= 1
                    } else {
                        upvotedItems[article.objectID] = now
                        if let _ = downvotedItems[article.objectID] {
                            // previously downvoted
                            downvotedItems.removeValue(forKey: article.objectID)
                        } else {
                            // no prior votes
                            points += 1
                        }
                    }
                } else {
                    // downvote clicked
                    if let _ = downvotedItems[article.objectID] {
                        // previously downvoted
                        downvotedItems.removeValue(forKey: article.objectID)
                        points -= 1
                    } else {
                        downvotedItems[article.objectID] = now
                        if let _ = upvotedItems[article.objectID] {
                            // previously upvoted
                            upvotedItems.removeValue(forKey: article.objectID)
                        } else {
                            // no prior votes
                            points = points + 1
                        }
                    }
                }
                
                if targetPoints <= points {
                    targetPoints = targetPoints * self.TARGET_POINTS_MULTIPLIER
                    status += 1
                    self.userStatus = self.getUserStatus(status)
                }
                
                upvotedItemsCount = upvotedItems.count
                downvotedItemsCount = downvotedItems.count
                
                user["upvotedItems"] = upvotedItems as Any?
                user["downvotedItems"] = downvotedItems as Any?
                user["upvotedItemsCount"] = upvotedItemsCount as Any?
                user["downvotedItemsCount"] = downvotedItemsCount as Any?
                user["points"] = points as Any?
                user["targetPoints"] = targetPoints as Any?
                user["status"] = status as Any?
                
                mutableData.value = user
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
            onComplete(self.userStatus)
            self.userStatus = nil
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
                    Analytics.logEvent("save_article", parameters: [
                        AnalyticsParameterItemID: article["objectID"] ?? "",
                        AnalyticsParameterItemCategory: article["mainTheme"] ?? "",
                        "item_source": article["source"] ?? "",
                        AnalyticsParameterContentType: article["type"] ?? ""
                    ])
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
            
            onComplete()
        })
    }
    
    
    // Video Feed
    func observeVideos(query: DatabaseQuery, onComplete: @escaping ([Video]) -> ()) {
        var videos = [Video]()
        var videoIds = [String]()
        
        query.observe(.childAdded) { (snap) in
            let video = Video(snapshot: snap)
            
            if !videoIds.contains(snap.key) {
                let isReported = video.isReported ?? false
                if !isReported {
                    videos.append(video)
                    videoIds.append(snap.key)
                }
            }
            onComplete(videos)
        }
        
        query.observe(.childChanged) { (snap) in
            let video = Video(snapshot: snap)
            
            if let index = videoIds.firstIndex(of: snap.key) {
                let isReported = video.isReported ?? false
                if isReported {
                    videos.remove(at: index)
                    videoIds.remove(at: index)
                } else {
                    videos[index] = video
                }
            }
            onComplete(videos)
        }
        
        query.observe(.childRemoved) { (snap) in
            if let index = videoIds.firstIndex(of: snap.key) {
                videos.remove(at: index)
                videoIds.remove(at: index)
            }
            onComplete(videos)
        }
        
        query.observe(.childMoved) { (snap, previousChildKey) in
            if let index = videoIds.firstIndex(of: snap.key) {
                videoIds.remove(at: index)
                videos.remove(at: index)
            }
            let newIndex = (previousChildKey != nil) ? videoIds.firstIndex(of: previousChildKey!)! + 1 : 0
            videoIds.insert(snap.key, at: newIndex)
            videos.insert(Video(snapshot: snap), at: newIndex)
            onComplete(videos)
        }
    }
    
    func getVideoFeed(onComplete: @escaping ([Video]) -> ()) {
        let query = videoRef.queryOrdered(byChild: "trendingIndex").queryLimited(toFirst: self.limit)
//        query.keepSynced(true)
        observedFeedQueries.append(query)
        observeVideos(query: query, onComplete: onComplete)
    }
    
    func getVideoFeed(startAt: String, onComplete: @escaping ([Video]) -> ()) {
        let query = videoRef.queryOrdered(byChild: "trendingIndex").queryLimited(toFirst: self.limit + 1).queryStarting(atValue: startAt)
//        query.keepSynced(true)
        observedFeedQueries.append(query)
        observeVideos(query: query, onComplete: onComplete)
    }
    
    func observeVideosForMainFeed(query: DatabaseQuery, onComplete: @escaping ([Video]) -> ()) {
        var videos = [Video]()
        var videoIds = [String]()
        
        query.observeSingleEvent(of: .value) { (snap) in
            // if value changes, reset all articles and remove all observers
            if videoIds.count > 0 {
                for videoId in videoIds {
                    self.videoRef.child(videoId).removeAllObservers()
                }
                videos.removeAll()
                videoIds.removeAll()
            }
            
            guard let _ = snap.value else { return }
            for case let data as DataSnapshot in snap.children {
                let video = Video(snapshot: data)
                if !videoIds.contains(video.objectID) {
                    let isReported = video.isReported ?? false
                    if !isReported {
                        videos.append(video)
                        videoIds.append(video.objectID)
                    }
                } else {
                    if let index = videoIds.firstIndex(of: video.objectID) {
                        let isReported = video.isReported ?? false
                        if isReported {
                            self.videoRef.child(video.objectID).removeAllObservers()
                            videos.remove(at: index)
                            videoIds.remove(at: index)
                        } else {
                            videos[index] = video
                        }
                    }
                }
            }
            onComplete(videos)
        }
    }
    
    func getVideosForMainFeed(onComplete: @escaping ([Video]) -> ()) {
        let cutoffDate = -DateUtils.getThreeDaysAgoMidnight()
        let query = videoRef.queryOrdered(byChild: "pubDate").queryEnding(atValue: cutoffDate)
        observedFeedQueries.append(query)
        observeVideosForMainFeed(query: query, onComplete: onComplete)
    }
    
    func getSingleVideo(id: String, onComplete: @escaping (Video) -> ()) {
        let query = videoRef.child(id)
        query.observeSingleEvent(of: .value, with: { (snap) in
            if let _ = snap.value {
                let video = Video(snapshot: snap)
                onComplete(video)
            }
        })
    }
    
    func observeSingleVideo(id: String, onComplete: @escaping (Video) -> ()) {
        let query = videoRef.child(id)
        query.observe(.value) { (snap) in
            if let _ = snap.value {
                let video = Video(snapshot: snap)
                onComplete(video)
            }
        }
        self.observedVideosQueries[id] = query
    }
    
    
    // Video Feed Cells
    func updateVideoVote(video: Video, actionIsUpvote: Bool, wasUpvoted: Bool, wasDownvoted: Bool, onComplete: @escaping () -> ()) {
        let query = videoRef.child(video.objectID)
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        
        query.runTransactionBlock({ (mutableData) -> TransactionResult in
            if var video = mutableData.value as? [String: Any] {
                var upvoters = video["upvoters"] as? [String: Double] ?? [:]
                var downvoters = video["downvoters"] as? [String: Double] ?? [:]
                var voteCount = video["voteCount"] as? Int ?? 0
                
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
                
                video["upvoters"] = upvoters as Any?
                video["downvoters"] = downvoters as Any?
                video["voteCount"] = voteCount as Any?
                video["changedSinceLastJob"] = true as Any?
                
                mutableData.value = video
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            onComplete()
        })
    }
    
    func updateUserVote(video: Video, actionIsUpvote: Bool, onComplete: @escaping (String?) -> ()) {
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        
        userRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            if var user = mutableData.value as? [String: Any] {
                var upvotedItems = user["upvotedItems"] as? [String: Double] ?? [:]
                var downvotedItems = user["downvotedItems"] as? [String: Double] ?? [:]
                var upvotedItemsCount = user["upvotedItemsCount"] as? Int ?? 0
                var downvotedItemsCount = user["downvotedItemsCount"] as? Int ?? 0
                var points = user["points"] as? Double ?? 0
                var targetPoints = user["targetPoints"] as? Double ?? 0
                var status = user["status"] as? Int ?? 0
                
                if actionIsUpvote {
                    // upvote clicked
                    if let _ = upvotedItems[video.objectID] {
                        // previously upvoted
                        upvotedItems.removeValue(forKey: video.objectID)
                        points -= 1
                    } else {
                        upvotedItems[video.objectID] = now
                        if let _ = downvotedItems[video.objectID] {
                            // previously downvoted
                            downvotedItems.removeValue(forKey: video.objectID)
                        } else {
                            // no prior votes
                            points += 1
                        }
                    }
                } else {
                    // downvote clicked
                    if let _ = downvotedItems[video.objectID] {
                        // previously downvoted
                        downvotedItems.removeValue(forKey: video.objectID)
                        points -= 1
                    } else {
                        downvotedItems[video.objectID] = now
                        if let _ = upvotedItems[video.objectID] {
                            // previously upvoted
                            upvotedItems.removeValue(forKey: video.objectID)
                        } else {
                            // no prior votes
                            points = points + 1
                        }
                    }
                }
                
                if targetPoints <= points {
                    targetPoints = targetPoints * self.TARGET_POINTS_MULTIPLIER
                    status += 1
                    self.userStatus = self.getUserStatus(status)
                }
                
                upvotedItemsCount = upvotedItems.count
                downvotedItemsCount = downvotedItems.count
                
                user["upvotedItems"] = upvotedItems as Any?
                user["downvotedItems"] = downvotedItems as Any?
                user["upvotedItemsCount"] = upvotedItemsCount as Any?
                user["downvotedItemsCount"] = downvotedItemsCount as Any?
                user["points"] = points as Any?
                user["targetPoints"] = targetPoints as Any?
                user["status"] = status as Any?
                
                mutableData.value = user
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
            onComplete(self.userStatus)
            self.userStatus = nil
        })
    }
    
    func updateVideoSave(video: Video, onComplete: @escaping () -> ()) {
        let query = videoRef.child(video.objectID)
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        
        query.runTransactionBlock({ (mutableData) -> TransactionResult in
            if var video = mutableData.value as? [String: Any] {
                var savers = video["savers"] as? [String: Double] ?? [:]
                var saveCount = video["saveCount"] as? Int ?? 0
                
                if let _ = savers[self.uid] {
                    savers.removeValue(forKey: self.uid)
                } else {
                    savers[self.uid] = now
                }
                saveCount = savers.count
                
                video["savers"] = savers as Any?
                video["saveCount"] = saveCount as Any?
                video["changedSinceLastJob"] = true as Any?
                
                mutableData.value = video
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            onComplete()
        })
    }
    
    func updateUserSave(video: Video, onComplete: @escaping () -> ()) {
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        
        userRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            if var user = mutableData.value as? [String: Any] {
                var savedItems = user["savedItems"] as? [String: Double] ?? [:]
                var savedItemsCount = user["savedItemsCount"] as? Int ?? 0
                
                if let _ = savedItems[video.objectID] {
                    savedItems.removeValue(forKey: video.objectID)
                } else {
                    savedItems[video.objectID] = now
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
            
            if let index = commentIds.firstIndex(of: snap.key) {
                comments[index] = comment
            }
            onComplete(comments)
        }
        
        query.observe(.childRemoved) { (snap) in
            if let index = commentIds.firstIndex(of: snap.key) {
                comments.remove(at: index)
                commentIds.remove(at: index)
            }
            onComplete(comments)
        }
        
        query.observe(.childMoved) { (snap, previousChildKey) in
            if let index = commentIds.firstIndex(of: snap.key) {
                commentIds.remove(at: index)
                comments.remove(at: index)
            }
            let newIndex = (previousChildKey != nil) ? commentIds.firstIndex(of: previousChildKey!)! + 1 : 0
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
                print(error.localizedDescription)
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
    
    func sendComment(articleId: String, commentText: String?, commentImageData: Data?, onComplete: @escaping (String?) -> (), onError: @escaping (String) -> ()) {
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
        
        if let key = key {
            if let imageData = commentImageData {
                saveImageToStorage(key: key, imageData: imageData, onComplete: { (url) in
                    commentAsDict["imageUrl"] = url
                    commentRef.child(key).setValue(commentAsDict) { (error, ref) in
                        if let error = error {
                            onError(error.localizedDescription)
                            return
                        }
                        
                        self.updateArticleComment(articleId: articleId)
                        self.updateUserComment(articleId: articleId) { (userStatus) in
                            onComplete(userStatus)
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
                    
                    self.updateArticleComment(articleId: articleId)
                    self.updateUserComment(articleId: articleId) { (userStatus) in
                        onComplete(userStatus)
                    }
                }
            }
        } else {
            onError("An unexpected error occurred")
        }
    }
    
    func sendUrlComment(articleId: String, urlLink: String, urlTitle: String, urlImageUrl: String?, urlSource: String?) {
        let commentRef = self.database.reference(withPath: "comment/\(articleId)")
        
        let now = -floor(Double(Date().timeIntervalSince1970 * 1000))
        if let key = commentRef.childByAutoId().key {
        
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
            return
        } else {
            print("sendUrlComment: failed to generate key")
            return
        }
    }
    
    func updateArticleComment(articleId: String) {
        let query = articleRef.child(articleId)
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        var token: String = ""
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print(error.localizedDescription)
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
                    print(error.localizedDescription)
                }
                
            })
        }
    }
    
    func updateUserComment(articleId: String, onComplete: @escaping (String?) -> ()) {
        userRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            if var user = mutableData.value as? [String: Any] {
                var commentedItems = user["commentedItems"] as? [String: Int] ?? [:]
                var commentedItemsCount = user["commentedItemsCount"] as? Int ?? 0
                var points = user["points"] as? Double ?? 0
                var targetPoints = user["targetPoints"] as? Double ?? 0
                var status = user["status"] as? Int ?? 0
                
                commentedItemsCount += 1
                commentedItems[articleId] = commentedItemsCount
                points += 1
                
                if targetPoints <= points {
                    targetPoints = targetPoints * self.TARGET_POINTS_MULTIPLIER
                    status += 1
                    self.userStatus = self.getUserStatus(status)
                }
                
                user["commentedItems"] = commentedItems as Any?
                user["commentedItemsCount"] = commentedItemsCount as Any?
                user["points"] = points as Any?
                user["targetPoints"] = targetPoints as Any?
                user["status"] = status as Any?
                
                mutableData.value = user
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
            onComplete(self.userStatus)
            self.userStatus = nil
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
    func createPost(post: Dictionary<String, Any?>, postImageData: Data?, onComplete: @escaping (String?) -> (), onError: @escaping (String) -> ()) {
        var post = post
        
        if let imageData = postImageData {
            saveImageToStorage(key: post["objectID"] as! String, imageData: imageData, onComplete: { (url) in
                post["postImageUrl"] = url
                
                self.postRef.child(post["objectID"] as! String).setValue(post, withCompletionBlock: { (error, ref) in
                    if let error = error {
                        onError(error.localizedDescription)
                        return
                    }
                    
                    self.updateUserPost(post: post) { (userStatus) in
                        onComplete(userStatus)
                    }
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
                
                self.updateUserPost(post: post) { (userStatus) in
                    onComplete(userStatus)
                }
            })
        }
    }
    
    func updateUserPost(post: Dictionary<String, Any?>, onComplete: @escaping (String?) -> ()) {
        userRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            if var user = mutableData.value as? [String: Any] {
                var createdPosts = user["createdPosts"] as? [String: Double] ?? [:]
                var createdPostsCount = user["createdPostsCount"] as? Int ?? 0
                var points = user["points"] as? Double ?? 0
                var targetPoints = user["targetPoints"] as? Double ?? 0
                var status = user["status"] as? Int ?? 0
                
                createdPosts[post["objectID"] as! String] = post["postDate"] as? Double
                createdPostsCount = createdPosts.count
                points = points + 1
                
                if targetPoints <= points {
                    targetPoints = targetPoints * self.TARGET_POINTS_MULTIPLIER
                    status += 1
                    self.userStatus = self.getUserStatus(status)
                }
                
                user["createdPosts"] = createdPosts as Any?
                user["createdPostsCount"] = createdPostsCount as Any?
                user["points"] = points as Any?
                user["targetPoints"] = targetPoints as Any?
                user["status"] = status as Any?
                
                mutableData.value = user
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
            onComplete(self.userStatus)
            self.userStatus = nil
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
    
    func setArticleReadTime(articleId: String, readTime: Int) {
        articleRef.child("\(articleId)/readTime").setValue(readTime)
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
    
    func setRecDealsNotificationPreference(bool: Bool) {
        if !bool {
            recDealsPreferenceRef.setValue(bool)
        } else {
            recDealsPreferenceRef.removeValue()
        }
    }
    
    func setSavedArticlesReminderNotificationPreference(bool: Bool) {
        if !bool {
            savedArticlesReminderPreferenceRef.setValue(bool)
            Messaging.messaging().subscribe(toTopic: "savedArticlesReminderPush")
        } else {
            savedArticlesReminderPreferenceRef.removeValue()
            Messaging.messaging().unsubscribe(fromTopic: "savedArticlesReminderPush")
        }
    }
    
    func setLocationNotificationPreference(bool: Bool) {
        if !bool {
            locationPreferenceRef.setValue(bool)
        } else {
            locationPreferenceRef.removeValue()
        }
    }
    
    func setVideosInFeedPreference(_ bool: Bool) {
        if !bool {
            videosInFeedPreferenceRef.child("showVideos").setValue(bool)
        } else {
            videosInFeedPreferenceRef.child("showVideos").removeValue()
        }
    }
    
    func setVideosInFeedPreference(for source: String, _ bool: Bool) {
        if !bool {
            videosInFeedPreferenceRef.child("channelsToRemove").child(source).setValue(Date().timeIntervalSince1970 * 1000.0)
        } else {
            videosInFeedPreferenceRef.child("channelsToRemove").child(source).removeValue()
        }
    }
    
    
    // Data collection
    func recordOpenArticleDetails(articleId: String, mainTheme: String) {
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        articleRef.child(articleId).runTransactionBlock({ (mutableData) -> TransactionResult in
            if var article = mutableData.value as? [String: Any] {
                var openedBy = article["openedBy"] as? [String: Double] ?? [:]
                var openCount = article["openCount"] as? Int ?? 0
                
                openedBy[self.uid] = now
                openCount += 1
                
                article["openedBy"] = openedBy as Any?
                article["openCount"] = openCount as Any?
                article["changedSinceLastJob"] = true as Any?
                
                mutableData.value = article
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
        })
        
        userRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            if var user = mutableData.value as? [String: Any] {
                var openedArticles = user["openedArticles"] as? [String: Double] ?? [:]
                var openedThemes = user["openedThemes"] as? [String: Int] ?? [:]
                
                let themeOpenCount = openedThemes[mainTheme] ?? 0
                
                openedArticles[articleId] = now
                openedThemes[mainTheme] = themeOpenCount + 1
                
                user["openedArticles"] = openedArticles as Any?
                user["openedThemes"] = openedThemes as Any?
                
                mutableData.value = user
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
        })
    }
    
    func recordOpenVideoDetails(videoId: String) {	
        let now = floor(Double(Date().timeIntervalSince1970 * 1000))
        videoRef.child(videoId).runTransactionBlock({ (mutableData) -> TransactionResult in
            if var video = mutableData.value as? [String: Any] {
                var viewedBy = video["viewedBy"] as? [String: Double] ?? [:]
                var viewCount = video["viewCount"] as? Int ?? 0
                
                viewedBy[self.uid] = now
                viewCount += 1
                
                video["viewedBy"] = viewedBy as Any?
                video["viewCount"] = viewCount as Any?
                video["changedSinceLastJob"] = true as Any?
                
                mutableData.value = video
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
        })
        
        userRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            if var user = mutableData.value as? [String: Any] {
                var viewedVideos = user["viewedVideos"] as? [String: Double] ?? [:]
                
                viewedVideos[videoId] = now
                
                user["viewedVideos"] = viewedVideos as Any?
                
                mutableData.value = user
                
                return TransactionResult.success(withValue: mutableData)
            }
            return TransactionResult.success(withValue: mutableData)
        }, andCompletionBlock: { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
        })
    }
    
    func setReferrerFor(uid: String, referrer: String) {
        let updates = ["/\(uid)/referredBy": referrer]
        self.userRef.updateChildValues(updates)
    }
    
    func logNotificationClicked(uid: String?, itemId: String = "", type: String) {
        Analytics.logEvent("click_notification", parameters: [
            AnalyticsParameterItemID: itemId,
            "notification_type": type
        ])
        
        guard let uid = uid else { return }
        let data: [String: Any] = [
            "userId": uid,
            "itemId": itemId,
            "type": type,
            "date": Date().timeIntervalSince1970 * 1000
        ]
        
        if let key = self.notificationRef.child(uid).childByAutoId().key {
            self.notificationRef.child(uid).child(key).updateChildValues(data)
        }
    }
    
    func logSeenItemEvent(uid: String, itemId: String, type: String) {
        let now = Date().timeIntervalSince1970 * 1000
        if (type == "article" || type == "post") {
            articleRef.child(itemId).child("seenBy").child(uid).setValue(now)
        } else if type == "video" {
            videoRef.child(itemId).child("seenBy").child(uid).setValue(now)
        }
    }
    
    func logItemTimeLog(_ timeLog: TimeLog) {
        let timeLogAsDict: [String : Any] = [
            "itemId": timeLog.itemId ?? "",
            "userId": timeLog.userId ?? "",
            "openTime": timeLog.openTime ?? 0,
            "closeTime": timeLog.closeTime ?? 0,
            "activeTime": timeLog.activeTime ?? 0,
            "percentScroll": timeLog.percentScroll ?? 0,
            "percentReadTimeActive": timeLog.percentReadTimeActive ?? 0,
            "type": timeLog.type ?? ""
        ]
        guard let key = timeLogRef.childByAutoId().key else { return }
        timeLogRef.child(key).setValue(timeLogAsDict)
    }
    
    func logSurveyResponse(_ response: Bool) {
        surveyRef.child(uid).setValue(response)
    }
}
