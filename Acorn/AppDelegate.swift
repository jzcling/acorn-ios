//
//  AppDelegate.swift
//  Acorn
//
//  Created by macOS on 31/7/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseUI
import GoogleSignIn
import MaterialComponents
import UserNotifications
import DropDown
import InstantSearch
import InstantSearchCore
import FirebaseMessaging
import SwiftSoup
import DeviceKit
import Toast_Swift
//import YoutubeKit
import SQLite3
import Fabric
import Crashlytics
import CoreLocation
import PIPKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    var window: UIWindow?
    
    let locationManager = CLLocationManager()
    
    let dataSource = NetworkDataSource.instance
    let localDb = LocalDb.instance
    
    let defaults = UserDefaults.standard
    
    let globals = Globals.instance
    
    let toastManager = ToastManager.shared
    
    lazy var user = Auth.auth().currentUser
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    lazy var rootVC = mainStoryboard.instantiateViewController(withIdentifier: "RootNavigation")
    lazy var feedVC = mainStoryboard.instantiateViewController(withIdentifier: "Feed") as? FeedViewController
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (_, _) in }
        application.registerForRemoteNotifications()
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        FirebaseApp.configure()
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        let authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        let providers: [FUIAuthProvider] = [FUIGoogleAuth(), FUIFacebookAuth(), FUIEmailAuth()]
        authUI?.providers = providers
        
        registerSettingsBundle()
        
        Messaging.messaging().delegate = self
        
        Database.database().isPersistenceEnabled = true
        
//        dataSource.setupAlgoliaClient {
//            if let apiKey = self.dataSource.algoliaApiKey {
//                InstantSearch.shared.configure(appID: "O96PPLSF19", apiKey: apiKey, index: "article")
//            }
//        }
        
//        dataSource.getYouTubeApi() { (apiKey) in
//            YoutubeKit.shared.setAPIKey(apiKey)
//        }
        
        DropDown.startListeningToKeyboard()
        toastManager.isTapToDismissEnabled = true
        toastManager.isQueueEnabled = true
        
        Fabric.with([Crashlytics.self])
        Fabric.sharedSDK().debug = true
        
        return true
    }
    
    func registerSettingsBundle() {
        var appDefaults = [String: AnyObject]()
        appDefaults["nightModePref"] = false as AnyObject
        appDefaults["commentNotifPref"] = true as AnyObject
        appDefaults["recArticlesNotifPref"] = true as AnyObject
        appDefaults["recDealsNotifPref"] = true as AnyObject
        appDefaults["savedArticlesReminderNotifPref"] = true as AnyObject
        defaults.register(defaults: appDefaults)
        defaults.synchronize()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        guard let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String else {
            return false
        }
        return self.handleOpenUrl(url, sourceApplication: sourceApplication)
    }
    
    func handleOpenUrl(_ url: URL, sourceApplication: String?) -> Bool {
        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromUniversalLink: url) {
            handleDynamicLink(dynamicLink: dynamicLink)
            return true
        }
        if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
            return true
        }
        return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: nil)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        let dataDict = ["token": fcmToken]
        globals.token = fcmToken
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if userInfo["type"] as? String == "comment" {
            updateCommentNotificationList(userInfo)
            completionHandler(.newData)
        } else if userInfo["type"] as? String == "recArticles" {
            let recArticlesPref = self.defaults.bool(forKey: "recArticlesNotifPref")
            if recArticlesPref {
                let waitTime = Double(arc4random_uniform(10))
                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                    self.scheduleRecommendedArticlesPush() {
                        self.updateNotificationsBadge(notificationsButton: (self.feedVC?.notificationsButton)!)
                        completionHandler(.newData)
                    }
                }
            }
        } else if userInfo["type"] as? String == "recDeals" {
            let recDealsPref = self.defaults.bool(forKey: "recDealsNotifPref")
            if recDealsPref {
                let waitTime = Double(arc4random_uniform(10))
                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                    self.scheduleRecommendedDealsPush() {
                        self.updateNotificationsBadge(notificationsButton: (self.feedVC?.notificationsButton)!)
                        completionHandler(.newData)
                    }
                }
            }
        } else if userInfo["type"] as? String == "manualArticle" {
            completionHandler(.newData)
        } else if userInfo["type"] as? String == "savedArticlesReminderPush" {
            let savedArticlesReminderPref = self.defaults.bool(forKey: "savedArticlesReminderNotifPref")
            if savedArticlesReminderPref {
                let waitTime = Double(arc4random_uniform(10))
                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                    self.scheduleSavedArticlesReminderPush() {
                        self.updateNotificationsBadge(notificationsButton: (self.feedVC?.notificationsButton)!)
                        completionHandler(.newData)
                    }
                }
            }
        } else if userInfo["type"] as? String == "promotional" {
            completionHandler(.newData)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        if userInfo["type"] as? String == "comment" {
            updateCommentNotificationList(userInfo)
            completionHandler([.alert, .sound])
        } else if userInfo["type"] as? String == "recArticles" {
            let recArticlesPref = self.defaults.bool(forKey: "recArticlesNotifPref")
            if recArticlesPref {
                let waitTime = Double(arc4random_uniform(10))
                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                    self.scheduleRecommendedArticlesPush() {
                        self.updateNotificationsBadge(notificationsButton: (self.feedVC?.notificationsButton)!)
                        completionHandler([])
                    }
                }
            }
        } else if userInfo["type"] as? String == "recDeals" {
            let recDealsPref = self.defaults.bool(forKey: "recDealsNotifPref")
            if recDealsPref {
                let waitTime = Double(arc4random_uniform(10))
                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                    self.scheduleRecommendedDealsPush() {
                        self.updateNotificationsBadge(notificationsButton: (self.feedVC?.notificationsButton)!)
                        completionHandler([])
                    }
                }
            }
        } else if userInfo["type"] as? String == "manualArticle" {
            completionHandler([.alert, .sound])
        } else if userInfo["type"] as? String == "savedArticlesReminderPush" {
            let savedArticlesReminderPref = self.defaults.bool(forKey: "savedArticlesReminderNotifPref")
            if savedArticlesReminderPref {
                let waitTime = Double(arc4random_uniform(10))
                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                    self.scheduleSavedArticlesReminderPush() {
                        self.updateNotificationsBadge(notificationsButton: (self.feedVC?.notificationsButton)!)
                        completionHandler([])
                    }
                }
            }
        } else if userInfo["type"] as? String == "savedAddress" {
            completionHandler([.alert, .sound])
        } else if userInfo["type"] as? String == "location" {
            completionHandler([.alert, .sound])
        } else if userInfo["type"] as? String == "promotional" {
            completionHandler([.alert, .sound])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if userInfo["type"] as? String == "comment" {
            guard let articleId = userInfo["articleId"] as? String else { return }
            dataSource.logNotificationClicked(uid: user?.uid, itemId: articleId, type: "Comment")
            openComments(articleId)
        } else if userInfo["type"] as? String == "recArticlesLocal" {
            guard let articleId = userInfo["articleId"] as? String else { return }
            if (userInfo["link"] != nil && userInfo["link"] as? String != "") {
                dataSource.recordOpenArticleDetails(articleId: articleId, mainTheme: userInfo["mainTheme"] as? String ?? "General")
                dataSource.logNotificationClicked(uid: user?.uid, itemId: articleId, type: "Recommended Article")
                openArticle(articleId)
            } else {
                dataSource.logNotificationClicked(uid: user?.uid, itemId: articleId, type: "Recommended Article")
                openComments(articleId)
            }
        } else if userInfo["type"] as? String == "recDealsLocal" {
            guard let articleId = userInfo["articleId"] as? String else { return }
            if (userInfo["link"] != nil && userInfo["link"] as? String != "") {
                dataSource.recordOpenArticleDetails(articleId: articleId, mainTheme: userInfo["mainTheme"] as? String ?? "General")
                dataSource.logNotificationClicked(uid: user?.uid, itemId: articleId, type: "Recommended Deal")
                openArticle(articleId)
            } else {
                dataSource.logNotificationClicked(uid: user?.uid, itemId: articleId, type: "Recommended Deal")
                openComments(articleId)
            }
        } else if userInfo["type"] as? String == "manualArticle" {
            guard let articleId = userInfo["articleId"] as? String else { return }
            dataSource.recordOpenArticleDetails(articleId: articleId, mainTheme: userInfo["mainTheme"] as? String ?? "General")
            dataSource.logNotificationClicked(uid: user?.uid, itemId: articleId, type: "Manual Article")
            openArticle(articleId)
        } else if userInfo["type"] as? String == "savedArticlesReminderLocal" {
            guard let articleId = userInfo["articleId"] as? String else { return }
            dataSource.recordOpenArticleDetails(articleId: articleId, mainTheme: userInfo["mainTheme"] as? String ?? "General")
            dataSource.logNotificationClicked(uid: user?.uid, itemId: articleId, type: "Saved Article Reminder")
            openArticle(articleId)
        } else if userInfo["type"] as? String == "savedAddress" {
            guard let articleId = userInfo["articleId"] as? String else { return }
            let postcode = userInfo["postcode"] as? [String] ?? [String]()
            dataSource.logNotificationClicked(uid: user?.uid, itemId: articleId, type: "Saved Address Reminder")
            openArticle(articleId, postcode)
        } else if userInfo["type"] as? String == "location" {
            guard let locale = userInfo["locale"] as? String else { return }
            dataSource.logNotificationClicked(uid: user?.uid, type: "Nearby")
            openNearby(locale: locale)
        } else if userInfo["type"] as? String == "promotional" {
            guard let storyboardId = userInfo["iosStoryboardId"] as? String else { return }
            let campaignId = userInfo["campaignId"] as? String
            dataSource.logNotificationClicked(uid: user?.uid, itemId: campaignId ?? "", type: "Promotional")
            if storyboardId == "Nearby", let search = userInfo["keyword"] as? String {
                openNearby(search: search)
            }
        }
        
        completionHandler()
    }
    
    func updateCommentNotificationList(_ userInfo: [AnyHashable: Any]) {
        var notificationsDict = self.defaults.dictionary(forKey: "notifications")
            
        guard let articleId = userInfo["articleId"] as? String else { return }
        let key = "c_\(articleId)"
        
        //type, articleId, text, title, source, imageUrl, theme, extra, timestamp
        let valueBuilder: StringBuilder = StringBuilder(string: "comment|•|") //type
        valueBuilder.append("\(articleId)|•|") //articleId
        
        if let currentValue = notificationsDict?[key] as? String {
            let unreadCount = Int(currentValue.components(separatedBy: "|•|")[2].split(separator: " ")[0]) ?? 0
            valueBuilder.append("\(unreadCount + 1) new comments on an article you follow|•|") //text
        } else {
            valueBuilder.append("1 new comment on an article you follow|•|") //text
        }
        
        valueBuilder.append("\(userInfo["title"] ?? "")|•|") //title
        valueBuilder.append("\(userInfo["source"] ?? "")|•|") //source
        valueBuilder.append("\(userInfo["imageUrl"] ?? "")|•|") //imageUrl
        valueBuilder.append("\(userInfo["mainTheme"] ?? "")|•|") //theme
        valueBuilder.append("\(userInfo["mainTheme"] ?? "")|•|") //extra
        valueBuilder.append("\(userInfo["timestamp"] ?? "")|•|") //timestamp
        valueBuilder.append("") //link
        
        notificationsDict![key] = valueBuilder.toString()
        self.defaults.set(notificationsDict, forKey: "notifications")
        
        UIApplication.shared.applicationIconBadgeNumber = notificationsDict?.count ?? 0
    }
    
    func openComments(_ articleId: String) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Comment") as? CommentViewController
        vc?.articleId = articleId
        self.window?.rootViewController = rootVC
        rootVC.present(vc!, animated:true)
    }
    
    func openArticle(_ articleId: String) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "WebView") as? WebViewViewController
        vc?.articleId = articleId
        vc?.feedVC = feedVC
        self.window?.rootViewController = rootVC
        rootVC.present(vc!, animated: false)
    }
    
    func openArticle(_ articleId: String, _ postcode: [String]) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "WebView") as? WebViewViewController
        vc?.articleId = articleId
        vc?.postcode = postcode
        vc?.feedVC = feedVC
        self.window?.rootViewController = rootVC
        rootVC.present(vc!, animated: false)
    }
    
    func openVideo(_ videoId: String) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "YTPlayer") as? YTPlayerViewController
        vc?.videoId = videoId
        self.window?.rootViewController = rootVC
//        rootVC.present(vc!, animated: false)
        PIPKit.show(with: vc!)
    }
    
    func openNearby(locale: String? = nil, search: String? = nil) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Nearby") as? NearbyViewController
        vc?.locale = locale
        vc?.keywordSearchText = search
        self.window?.rootViewController = rootVC
        rootVC.present(vc!, animated: false)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        if let user = Auth.auth().currentUser {
            self.dataSource.removeAllListenersOnUser(user: user)
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        print("deepLink: \(userActivity.webpageURL!)")
        //if dynamicLinks.matchesShortLinkFormat(userActivity.webpageURL!) {
            print("handling short link")
            DynamicLinks.dynamicLinks().resolveShortLink(userActivity.webpageURL!) { (url, error) in
                self.handleShortLink(url: url)
            }
            return true
        //}
//        let handled = DynamicLinks.dynamicLinks().handleUniversalLink(userActivity.webpageURL!) { (dynamicLink, error) in
//            if let link = dynamicLink {
//                print("link: \(String(describing: link.url))")
//                self.handleDynamicLink(dynamicLink: link)
//            }
//        }
//        return handled
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
            handleDynamicLink(dynamicLink: dynamicLink)
            return true
        }
        return false
    }
    
    func handleShortLink(url: URL?) {
        if let deepLink = url?.query?.components(separatedBy: "&")[0].components(separatedBy: "=")[1] {
            print("deepLink: \(deepLink)")
            let decodedLink = deepLink.removingPercentEncoding
            if let link = URL(string: decodedLink ?? "") {
                if url?.absoluteString.contains("invite") ?? false {
                    var referrer: String?
                    let components = URLComponents(url: link, resolvingAgainstBaseURL: false)
                    if let queryItems = components?.queryItems {
                        for query in queryItems {
                            switch query.name {
                            case "referrer":
                                referrer = query.value
                            default:
                                break
                            }
                        }
                        if let referrer = referrer {
                            self.feedVC?.referredBy = referrer
                        }
                    }
                } else if url?.absoluteString.contains("share") ?? false {
                    let lastSegment = link.lastPathComponent
                    if lastSegment == "article" {
                        var articleId: String?
                        var sharerId: String?
                        let components = URLComponents(url: link, resolvingAgainstBaseURL: false)
                        if let queryItems = components?.queryItems {
                            for query in queryItems {
                                print("\(query.name): \(query.value ?? "nil")")
                                switch query.name {
                                case "id":
                                    articleId = query.value
                                case "sharerId":
                                    sharerId = query.value
                                default:
                                    break
                                }
                            }
                            if let articleId = articleId {
                                print("articleId: \(articleId)")
                                if let sharerId = sharerId {
                                    self.feedVC?.referredBy = sharerId
                                }
                                DispatchQueue.main.async {
                                    self.openArticle(articleId)
                                }
                            }
                        }
                    } else if lastSegment == "video" {
                        var videoId: String?
                        var youtubeId: String?
                        var sharerId: String?
                        let components = URLComponents(url: link, resolvingAgainstBaseURL: false)
                        if let queryItems = components?.queryItems {
                            for query in queryItems {
                                print("\(query.name): \(query.value ?? "nil")")
                                switch query.name {
                                case "id":
                                    videoId = query.value
                                case "youtubeId":
                                    youtubeId = query.value
                                case "sharerId":
                                    sharerId = query.value
                                default:
                                    break
                                }
                            }
                            if let youtubeId = youtubeId {
                                if let sharerId = sharerId {
                                    self.feedVC?.referredBy = sharerId
                                }
                                DispatchQueue.main.async {
                                    self.openVideo(youtubeId)
                                }
                            }
                        }
                    }
                }
                
            }
        }
    }
    
    func handleDynamicLink(dynamicLink: DynamicLink) {
        var articleId: String?
        var sharerId: String?
        if let link = dynamicLink.url {
            let components = URLComponents(url: link, resolvingAgainstBaseURL: false)
            if let queryItems = components?.queryItems {
                for query in queryItems {
                    switch query.name {
                    case "id":
                        articleId = query.value
                    case "sharerId":
                        sharerId = query.value
                    default:
                        break
                    }
                }
                if let articleId = articleId {
                    print("articleId: \(articleId)")
                    self.openArticle(articleId)
                }
            }
        }
    }
}

extension AppDelegate: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        switch error {
        case .some(let error as NSError) where UInt(error.code) == FUIAuthErrorCode.userCancelledSignIn.rawValue:
            authPickerViewController(forAuthUI: authUI).view.makeToast(error.localizedDescription)
            break
        case .some(let error as NSError) where error.userInfo[NSUnderlyingErrorKey] != nil:
            authPickerViewController(forAuthUI: authUI).view.makeToast(error.localizedDescription)
            break
        case .some(let error):
            authPickerViewController(forAuthUI: authUI).view.makeToast(error.localizedDescription)
            break
        case .none:
            print("sign in successful")
//            self.feedVC?.didLogin = true
//            if let user = authDataResult?.user {
//                signed(in: user)
//            }
        }
    }
    
    func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
        return AuthPicker(nibName: "AuthPicker", bundle: Bundle.main, authUI: authUI)
    }
    
    func signed(in user: FirebaseUI.User) {
        user.reload()
        
        if !user.isEmailVerified {
            user.sendEmailVerification(completion: nil)
        } else {
            globals.isUserEmailVerified = true
        }
        
        print("appDelegate getUser:")
        dataSource.getUser(user: user) { (retrievedUser) in
            if let retrievedUser = retrievedUser {
                retrievedUser.uid = user.uid
                retrievedUser.displayName = user.displayName ?? ""
                retrievedUser.token = self.globals.token ?? ""
                retrievedUser.email = user.email ?? ""
                if !retrievedUser.isEmailVerified { retrievedUser.isEmailVerified = self.globals.isUserEmailVerified }
                retrievedUser.device = Device.current.description
                retrievedUser.creationTimeStamp = (user.metadata.creationDate?.timeIntervalSince1970 ?? 0) * 1000
                retrievedUser.lastSignInTimeStamp = (user.metadata.lastSignInDate?.timeIntervalSince1970 ?? 0) * 1000
                retrievedUser.openedSinceLastReport = true
                
                self.dataSource.setUser(retrievedUser.toDict())
            } else {
                let acornUser = AcornUser(uid: user.uid, displayName: user.displayName ?? "", token: self.globals.token ?? "", email: user.email ?? "", isEmailVerified: self.globals.isUserEmailVerified, device: Device.current.description, creationTimeStamp: (user.metadata.creationDate?.timeIntervalSince1970 ?? 0) * 1000, lastSignInTimeStamp: (user.metadata.lastSignInDate?.timeIntervalSince1970 ?? 0) * 1000, openedSinceLastReport: true)
                
                self.dataSource.setUser(acornUser.toDict())
            }
            self.feedVC?.didLogin = true
        }
    }
    
    func updateNotificationsBadge(notificationsButton: UIBarButtonItem) {
        let notificationsDict = self.defaults.dictionary(forKey: "notifications") ?? [String: String]()
        notificationsButton.setBadge(text: String(notificationsDict.count))
    }
    
    func scheduleRecommendedArticlesPush(onComplete: @escaping () -> ()) {
        getRecommendedArticlesNotificationContent { (content) in
            for notification in content {
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: notification.userInfo["key"] as! String, content: notification, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
            onComplete()
        }
    }
    
    func getRecommendedArticlesNotificationContent(onComplete: @escaping ([UNMutableNotificationContent]) -> ()) {
        self.dataSource.getRecommendedArticles { (articles) in
            var content = [UNMutableNotificationContent]()
            var notificationsDict = self.defaults.dictionary(forKey: "notifications") ?? [String: String]()
            
            var reversedArticles = articles
            reversedArticles.reverse()
            for article in reversedArticles {
                var source: String?
                var title: String?
                var link: String?
                if article.source != nil && article.source != "" {
                    source = article.source ?? ""
                    title = article.title ?? ""
                } else if article.postAuthor != nil && article.postAuthor != "" {
                    source = article.postAuthor ?? ""
                    title = article.postText ?? ""
                }
                
                link = article.link ?? ""
                
                var imageUrl: String?
                if article.imageUrl != nil && article.imageUrl != "" {
                    imageUrl = article.imageUrl
                } else if article.postImageUrl != nil && article.postImageUrl != "" {
                    imageUrl = article.postImageUrl
                }
                
                let pubDate = String(article.pubDate)
                let now = String(floor(Double(Date().timeIntervalSince1970 * 1000)))
                
                let key = "a_\(article.objectID)"
                
                //type, articleId, text, title, source, imageUrl, theme, extra, timestamp
                let valueBuilder: StringBuilder = StringBuilder(string: "article|•|") //type
                valueBuilder.append("\(article.objectID)|•|") //articleId
                valueBuilder.append("Recommended based on your subscription to \(article.mainTheme ?? "")|•|") //text
                valueBuilder.append("\(title ?? "")|•|") //title
                valueBuilder.append("\(source ?? "")|•|") //source
                valueBuilder.append("\(imageUrl ?? "")|•|") //imageUrl
                valueBuilder.append("\(article.mainTheme ?? "")|•|") //theme
                valueBuilder.append("\(pubDate)|•|") //extra
                valueBuilder.append("\(now)|•|") //timestamp
                valueBuilder.append(link ?? "") //link
                
                notificationsDict[key] = valueBuilder.toString()
                
                let notification = UNMutableNotificationContent()
                notification.title = title ?? ""
                notification.body = (source != nil && source != "") ? "\(source ?? "") • \(article.mainTheme ?? "")" : article.mainTheme ?? ""
                notification.sound = UNNotificationSound.default
                notification.userInfo["type"] = "recArticlesLocal"
                notification.userInfo["articleId"] = article.objectID
                notification.userInfo["mainTheme"] = article.mainTheme
                notification.userInfo["link"] = article.link
                notification.userInfo["key"] = key
                
                content.append(notification)
            }
            
            self.defaults.set(notificationsDict, forKey: "notifications")
            
            UIApplication.shared.applicationIconBadgeNumber = notificationsDict.count
            
            onComplete(content)
        }
    }
    
    func scheduleRecommendedDealsPush(onComplete: @escaping () -> ()) {
        getRecommendedDealsNotificationContent { (content) in
            for notification in content {
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: notification.userInfo["key"] as! String, content: notification, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
            onComplete()
        }
    }
    
    func getRecommendedDealsNotificationContent(onComplete: @escaping ([UNMutableNotificationContent]) -> ()) {
        self.dataSource.getRecommendedDeals { (articles) in
            var content = [UNMutableNotificationContent]()
            var notificationsDict = self.defaults.dictionary(forKey: "notifications") ?? [String: String]()
            
            var reversedArticles = articles
            reversedArticles.reverse()
            for article in reversedArticles {
                var source: String?
                var title: String?
                var link: String?
                if article.source != nil && article.source != "" {
                    source = article.source ?? ""
                    title = article.title ?? ""
                } else if article.postAuthor != nil && article.postAuthor != "" {
                    source = article.postAuthor ?? ""
                    title = article.postText ?? ""
                }
                
                link = article.link ?? ""
                
                var imageUrl: String?
                if article.imageUrl != nil && article.imageUrl != "" {
                    imageUrl = article.imageUrl
                } else if article.postImageUrl != nil && article.postImageUrl != "" {
                    imageUrl = article.postImageUrl
                }
                
                let pubDate = String(article.pubDate)
                let now = String(floor(Double(Date().timeIntervalSince1970 * 1000)))
                
                let key = "d_\(article.objectID)"
                
                //type, articleId, text, title, source, imageUrl, theme, extra, timestamp
                let valueBuilder: StringBuilder = StringBuilder(string: "deal|•|") //type
                valueBuilder.append("\(article.objectID)|•|") //articleId
                valueBuilder.append("Trending Deal|•|") //text
                valueBuilder.append("\(title ?? "")|•|") //title
                valueBuilder.append("\(source ?? "")|•|") //source
                valueBuilder.append("\(imageUrl ?? "")|•|") //imageUrl
                valueBuilder.append("\(article.mainTheme ?? "")|•|") //theme
                valueBuilder.append("\(pubDate)|•|") //extra
                valueBuilder.append("\(now)|•|") //timestamp
                valueBuilder.append(link ?? "") //link
                
                notificationsDict[key] = valueBuilder.toString()
                
                let notification = UNMutableNotificationContent()
                notification.title = title ?? ""
                notification.body = (source != nil && source != "") ? "\(source ?? "") • \(article.mainTheme ?? "")" : article.mainTheme ?? ""
                notification.sound = UNNotificationSound.default
                notification.userInfo["type"] = "recDealsLocal"
                notification.userInfo["articleId"] = article.objectID
                notification.userInfo["mainTheme"] = article.mainTheme
                notification.userInfo["link"] = article.link
                notification.userInfo["key"] = key
                
                content.append(notification)
            }
            
            self.defaults.set(notificationsDict, forKey: "notifications")
            
            UIApplication.shared.applicationIconBadgeNumber = notificationsDict.count
            
            onComplete(content)
        }
    }
    
    func scheduleSavedArticlesReminderPush(onComplete: @escaping () -> ()) {
        getSavedArticlesReminderNotificationContent { (content) in
            for notification in content {
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: notification.userInfo["key"] as! String, content: notification, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
            onComplete()
        }
    }
    
    func getSavedArticlesReminderNotificationContent(onComplete: @escaping ([UNMutableNotificationContent]) -> ()) {
        self.dataSource.getSavedArticlesReminderData() { (articles) in
            var content = [UNMutableNotificationContent]()
            var notificationsDict = self.defaults.dictionary(forKey: "notifications") ?? [String: String]()
            
            for article in articles {
                var source: String?
                var title: String?
                var link: String?
                if article.source != nil && article.source != "" {
                    source = article.source ?? ""
                    title = article.title ?? ""
                } else if article.postAuthor != nil && article.postAuthor != "" {
                    source = article.postAuthor ?? ""
                    title = article.postText ?? ""
                }
                
                link = article.link ?? ""
                
                var imageUrl: String?
                if article.imageUrl != nil && article.imageUrl != "" {
                    imageUrl = article.imageUrl
                } else if article.postImageUrl != nil && article.postImageUrl != "" {
                    imageUrl = article.postImageUrl
                }
                
                let pubDate = String(article.pubDate)
                let now = String(floor(Double(Date().timeIntervalSince1970 * 1000)))
                
                let key = "s_\(article.objectID)"
                
                //type, articleId, text, title, source, imageUrl, theme, extra, timestamp
                let valueBuilder: StringBuilder = StringBuilder(string: "savedArticleReminder|•|") //type
                valueBuilder.append("\(article.objectID)|•|") //articleId
                valueBuilder.append("Don't forget this saved article!|•|") //text
                valueBuilder.append("\(title ?? "")|•|") //title
                valueBuilder.append("\(source ?? "")|•|") //source
                valueBuilder.append("\(imageUrl ?? "")|•|") //imageUrl
                valueBuilder.append("\(article.mainTheme ?? "")|•|") //theme
                valueBuilder.append("\(pubDate)|•|") //extra
                valueBuilder.append("\(now)|•|") //timestamp
                valueBuilder.append(link ?? "") //link
                
                notificationsDict[key] = valueBuilder.toString()
                
                let notification = UNMutableNotificationContent()
                notification.title = "This item you saved is happening soon!"
                notification.body = title ?? ""
                notification.sound = UNNotificationSound.default
                notification.userInfo["type"] = "savedArticlesReminderLocal"
                notification.userInfo["articleId"] = article.objectID
                notification.userInfo["mainTheme"] = article.mainTheme
                notification.userInfo["link"] = article.link
                notification.userInfo["key"] = key
                
                content.append(notification)
            }
            
            self.defaults.set(notificationsDict, forKey: "notifications")
            
            UIApplication.shared.applicationIconBadgeNumber = notificationsDict.count
            
            onComplete(content)
        }
    }
}

extension Notification.Name {
    static let nightModeOn = Notification.Name("nightModeOn")
    static let nightModeOff = Notification.Name("nightModeOff")
}

extension AppDelegate: CLLocationManagerDelegate {
//    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
//        print("Entered \(region)")
//        if region is CLCircularRegion {
//            if region.identifier.prefix(7) != "article" {
//                handleEnterEvent(locale: region.identifier)
//            } else {
//                handleEnterEventForSavedAddress(articleId: String(region.identifier.suffix(8)))
//            }
//        }
//    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited \(region)")
        if region is CLCircularRegion {
            if region.identifier.prefix(7) != "article" {
                handleExitEvent(locale: region.identifier)
            } else {
                if let loc = manager.location {
                    handleExitEventForSavedAddress(articleId: String(region.identifier.suffix(8)), location: loc)
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        print("didDetermineState")
        if state == .inside {
            print("Entered \(region)")
            if region is CLCircularRegion {
                if region.identifier.prefix(7) != "article" {
                    handleEnterEvent(locale: region.identifier)
                } else {
                    handleEnterEventForSavedAddress(articleId: String(region.identifier.suffix(8)))
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        manager.requestState(for: region)
    }
    
    func handleEnterEvent(locale: String) {
        // create and schedule notification push
        let notification = createLocationNotification(for: locale)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10 * 60, repeats: false) // 10 min
        let request = UNNotificationRequest(identifier: "location", content: notification, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func handleExitEvent(locale: String) {
        // cancel notification push if scheduled
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["location"])
        
        // remove all geofences and add closest 5
        for region in locationManager.monitoredRegions {
            if region.identifier.prefix(7) != "article" {
                locationManager.stopMonitoring(for: region)
            }
        }
        self.getNearestLocales(from: locale, limit: 6) { (locales) in
            for station in locales {
                if let location = station.value["location"] as? CLLocation {
                    let region = CLCircularRegion(center: location.coordinate, radius: 1000, identifier: station.key)
                    region.notifyOnEntry = true
                    region.notifyOnExit = true
                    self.locationManager.startMonitoring(for: region)
                    print("monitoring \(station.key)")
                }
            }
        }
    }
    
    func createLocationNotification(for locale: String) -> UNMutableNotificationContent {
        let notification = UNMutableNotificationContent()
        notification.title = "📍 Check out what's around \(locale)!"
        notification.body = "Get deals, events and restaurant recommendations!"
        notification.sound = UNNotificationSound.default
        notification.userInfo["type"] = "location"
        notification.userInfo["locale"] = locale
        return notification
    }
    
    func getNearestLocales(from: String, limit: Int, onComplete: @escaping ([(key: String, value: [String: Any])]) -> ()) {
        getMrtStationMap { (mrtStationMap) in
            let fromLat = mrtStationMap[from]?["latitude"] as? Double
            let fromLng = mrtStationMap[from]?["longitude"] as? Double
            if let fromLat = fromLat, let fromLng = fromLng {
                let fromLoc = CLLocation(latitude: fromLat, longitude: fromLng)
                var distanceFrom = [String: [String: Any]]()
                for station in mrtStationMap {
                    if station.key != from {
                        let lat = station.value["latitude"] as? Double
                        let lng = station.value["longitude"] as? Double
                        if let lat = lat, let lng = lng {
                            let loc = CLLocation(latitude: lat, longitude: lng)
                            let distance = loc.distance(from: fromLoc)
                            distanceFrom[station.key] = ["location": loc, "distance": distance]
                        }
                    }
                }
                let sortedDistanceFrom = distanceFrom.sorted(by: { ($0.value["distance"]! as! Double) < ($1.value["distance"]! as! Double) })
                let cutoff = min(sortedDistanceFrom.count, limit)
                let result = Array(sortedDistanceFrom[..<cutoff])
                onComplete(result)
            }
        }
    }
    
    func getMrtStationMap(onComplete: @escaping ([String: [String: Any]]) -> ()) {
        if let mrtStationMap = defaults.object(forKey: "mrtStations") as? [String: [String: Any]] {
            onComplete(mrtStationMap)
        } else {
            dataSource.getMrtStations { (mrtStationMap) in
                self.defaults.set(mrtStationMap, forKey: "mrtStations")
                onComplete(mrtStationMap)
            }
        }
    }
    
    func handleEnterEventForSavedAddress(articleId: String) {
        let savedArticlesReminderPref = self.defaults.bool(forKey: "savedArticlesReminderNotifPref")
        if savedArticlesReminderPref {
            // create and schedule notification push
            createSavedAddressNotification(for: articleId) { (notification) in
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10 * 60, repeats: false) // 10 min
                let request = UNNotificationRequest(identifier: notification.userInfo["articleId"] as! String, content: notification, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    func handleExitEventForSavedAddress(articleId: String, location: CLLocation) {
        // cancel notification push if scheduled
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [articleId])
        
        // remove all geofences and add closest 5
        for region in locationManager.monitoredRegions {
            if region.identifier.prefix(7) == "article" {
                locationManager.stopMonitoring(for: region)
            }
        }
        
        let savedArticlesReminderPref = self.defaults.bool(forKey: "savedArticlesReminderNotifPref")
        if savedArticlesReminderPref {
            self.getNearestSavedAddresses(from: location, limit: 6) { addresses in
                for address in addresses {
                    if let addressLoc = address.value["location"] as? CLLocation {
                        let region = CLCircularRegion(center: addressLoc.coordinate, radius: 1000, identifier: "article_\(articleId)")
                        region.notifyOnEntry = true
                        region.notifyOnExit = true
                        self.locationManager.startMonitoring(for: region)
                        print("monitoring \(articleId)")
                    }
                }
            }
        }
    }
    
    func createSavedAddressNotification(for articleId: String, onComplete: @escaping (UNMutableNotificationContent) -> ()) {
        let notification = UNMutableNotificationContent()
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        self.dataSource.observeSingleArticle(articleId: articleId) { article in
            notification.title = "An item you saved is nearby!"
            notification.body = article.title ?? ""
            notification.sound = UNNotificationSound.default
            notification.userInfo["type"] = "savedAddress"
            notification.userInfo["articleId"] = articleId
            
            // in-app notification
            var notificationsDict = self.defaults.dictionary(forKey: "notifications") ?? [String: String]()
            var source: String?
            var title: String?
            var link: String?
            if article.source != nil && article.source != "" {
                source = article.source ?? ""
                title = article.title ?? ""
            } else if article.postAuthor != nil && article.postAuthor != "" {
                source = article.postAuthor ?? ""
                title = article.postText ?? ""
            }
            
            link = article.link ?? ""
            
            var imageUrl: String?
            if article.imageUrl != nil && article.imageUrl != "" {
                imageUrl = article.imageUrl
            } else if article.postImageUrl != nil && article.postImageUrl != "" {
                imageUrl = article.postImageUrl
            }
            
            let pubDate = String(article.pubDate)
            let now = String(floor(Double(Date().timeIntervalSince1970 * 1000)))
            
            let key = "s_\(article.objectID)"
            
            //type, articleId, text, title, source, imageUrl, theme, extra, timestamp
            let valueBuilder: StringBuilder = StringBuilder(string: "savedAddressReminder|•|") //type
            valueBuilder.append("\(article.objectID)|•|") //articleId
            valueBuilder.append("You were near this saved item today!|•|") //text
            valueBuilder.append("\(title ?? "")|•|") //title
            valueBuilder.append("\(source ?? "")|•|") //source
            valueBuilder.append("\(imageUrl ?? "")|•|") //imageUrl
            valueBuilder.append("\(article.mainTheme ?? "")|•|") //theme
            valueBuilder.append("\(pubDate)|•|") //extra
            valueBuilder.append("\(now)|•|") //timestamp
            valueBuilder.append(link ?? "") //link
            
            notificationsDict[key] = valueBuilder.toString()
            self.defaults.set(notificationsDict, forKey: "notifications")
            UIApplication.shared.applicationIconBadgeNumber = notificationsDict.count
            dispatchGroup.leave()
        }
        
        if let location = locationManager.location {
            dispatchGroup.enter()
            self.dataSource.getNearbyPostcode(for: articleId, location: location, radius: 1000) { postcodes in
                notification.userInfo["postcode"] = postcodes
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            onComplete(notification)
        }
    }
    
    func getNearestSavedAddresses(from: CLLocation, limit: Int, onComplete: @escaping ([(key: String, value: [String: Any])]) -> ()) {
        if let addresses = localDb.getAllAddresses() {
            var distanceFrom = [String: [String: Any]]()
            for address in addresses {
                let addressLoc = CLLocation(latitude: address.latitude, longitude: address.longitude)
                let distance = addressLoc.distance(from: from)
                if let loc = distanceFrom[address.articleId], let currentDistance = loc["distance"] as? Double {
                    if currentDistance > distance {
                        distanceFrom[address.articleId] = ["location": addressLoc, "distance": distance]
                    }
                } else {
                    distanceFrom[address.articleId] = ["location": addressLoc, "distance": distance]
                }
            }
            let sortedDistanceFrom = distanceFrom.sorted(by: { ($0.value["distance"]! as! Double) < ($1.value["distance"]! as! Double) })
            let cutoff = min(sortedDistanceFrom.count, limit)
            let result = Array(sortedDistanceFrom[..<cutoff])
            print("distance: \(result)")
            onComplete(result)
        }
    }
}
