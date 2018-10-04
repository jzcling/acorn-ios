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
import FirebaseMessaging
import SwiftSoup
import DeviceKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    var window: UIWindow?
    
    let dataSource = DataSource.instance
    
    let defaults = UserDefaults.standard
    
    var token: String?
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    lazy var rootVC = mainStoryboard.instantiateViewController(withIdentifier: "RootNavigation")
    lazy var feedVC = mainStoryboard.instantiateViewController(withIdentifier: "Feed") as? FeedViewController
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        let authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        let providers: [FUIAuthProvider] = [FUIGoogleAuth(), FUIFacebookAuth()]
        authUI?.providers = providers
        
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (_, _) in }
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        
        dataSource.setupAlgoliaClient {
            if let apiKey = self.dataSource.algoliaApiKey {
                InstantSearch.shared.configure(appID: "O96PPLSF19", apiKey: apiKey, index: "article")
            }
        }
        
        DropDown.startListeningToKeyboard()
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool {
        guard let sourceApplication = options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String else {
            return false
        }
        return self.handleOpenUrl(url, sourceApplication: sourceApplication)
    }
    
    func handleOpenUrl(_ url: URL, sourceApplication: String?) -> Bool {
        if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
            return true
        }
        return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: nil)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        
        
        let dataDict = ["token": fcmToken]
        token = fcmToken
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if userInfo["type"] as? String == "comment" {
            updateCommentNotificationList(userInfo)
        } else if userInfo["type"] as? String == "recArticles" {
            let recArticlesPref = self.defaults.bool(forKey: "recArticlesNotifPref")
            if recArticlesPref {
                let waitTime = Double(arc4random_uniform(10))
                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                    self.scheduleRecommendedArticlesPush() {
                        self.updateNotificationsBadge()
                    }
                }
            }
        }
        
        completionHandler(.newData)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        if userInfo["type"] as? String == "comment" {
            updateCommentNotificationList(userInfo)
        } else if userInfo["type"] as? String == "recArticles" {
            let recArticlesPref = self.defaults.bool(forKey: "recArticlesNotifPref")
            if recArticlesPref {
                let waitTime = Double(arc4random_uniform(10))
                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                    self.scheduleRecommendedArticlesPush() {
                        self.updateNotificationsBadge()
                    }
                }
            }
            return
        }
        
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if userInfo["type"] as? String == "comment" {
            guard let articleId = userInfo["articleId"] as? String else { return }
            openComments(articleId)
        } else if userInfo["type"] as? String == "recArticlesLocal" {
            guard let articleId = userInfo["articleId"] as? String else { return }
            openArticle(articleId)
        }
        
        completionHandler()
    }
    
    func updateCommentNotificationList(_ userInfo: [AnyHashable: Any]) {
        var notificationsDict = self.defaults.dictionary(forKey: "notifications")
            
        guard let articleId = userInfo["articleId"] as? String else { return }
        let key = "c_\(articleId)"
        
        //type, articleId, text, title, source, imageUrl, theme, extra, timestamp
        let valueBuilder: StringBuilder = StringBuilder(string: "comment•") //type
        valueBuilder.append("\(articleId)•") //articleId
        
        if let currentValue = notificationsDict?[key] as? String {
            let unreadCount = Int(currentValue.split(separator: "•")[2].split(separator: " ")[0]) ?? 0
            valueBuilder.append("\(unreadCount + 1) new comments on an article you follow•") //text
        } else {
            valueBuilder.append("1 new comment on an article you follow•") //text
        }
        
        valueBuilder.append("\(userInfo["title"] ?? "")•") //title
        valueBuilder.append("\(userInfo["source"] ?? "")•") //source
        valueBuilder.append("\(userInfo["imageUrl"] ?? "")•") //imageUrl
        valueBuilder.append("\(userInfo["mainTheme"] ?? "")•") //theme
        valueBuilder.append("\(userInfo["mainTheme"] ?? "")•") //extra
        valueBuilder.append("\(userInfo["timestamp"] ?? "")") //timestamp
        
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
        rootVC.present(vc!, animated: true)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
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
    
}

extension AppDelegate: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        switch error {
        case .some(let error as NSError) where UInt(error.code) == FUIAuthErrorCode.userCancelledSignIn.rawValue: break
            
        case .some(let error as NSError) where error.userInfo[NSUnderlyingErrorKey] != nil: break
            
        case .some(let error): break
            
        case .none:
            if let user = authDataResult?.user {
                signed(in: user)
            }
        }
    }
    
    func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
        return AuthPicker(nibName: "AuthPicker", bundle: Bundle.main, authUI: authUI)
    }
    
    func signed(in user: FirebaseUI.User) {
        user.reload()
        if !user.isEmailVerified {
            user.sendEmailVerification(completion: nil)
        }
        dataSource.getUser(user: user) { (retrievedUser) in
            if let retrievedUser = retrievedUser {
                retrievedUser.uid = user.uid
                retrievedUser.displayName = user.displayName ?? ""
                retrievedUser.token = self.token ?? ""
                retrievedUser.email = user.email ?? ""
                retrievedUser.device = Device().description
                retrievedUser.creationTimeStamp = (user.metadata.creationDate?.timeIntervalSince1970 ?? 0) * 1000
                retrievedUser.lastSignInTimeStamp = (user.metadata.lastSignInDate?.timeIntervalSince1970 ?? 0) * 1000
                
                self.dataSource.setUser(retrievedUser.toDict())
            } else {
                let acornUser = AcornUser(uid: user.uid, displayName: user.displayName ?? "", token: self.token ?? "", email: user.email ?? "", device: Device().description, creationTimeStamp: (user.metadata.creationDate?.timeIntervalSince1970 ?? 0) * 1000, lastSignInTimeStamp: (user.metadata.lastSignInDate?.timeIntervalSince1970 ?? 0) * 1000)
                
                self.dataSource.setUser(acornUser.toDict())
            }
        }
        Messaging.messaging().subscribe(toTopic: "iPhoneUsers") { error in
            
        }
    }
    
    func updateNotificationsBadge() {
        let notificationsDict = self.defaults.dictionary(forKey: "notifications") ?? [String: String]()
        self.feedVC?.notificationsButton.setBadge(text: String(notificationsDict.count))
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
                if article.source != nil && article.source != "" {
                    source = article.source ?? ""
                    title = article.title ?? ""
                } else if article.postAuthor != nil && article.postAuthor != "" {
                    source = article.postAuthor ?? ""
                    title = article.postText ?? ""
                }
                
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
                let valueBuilder: StringBuilder = StringBuilder(string: "article•") //type
                valueBuilder.append("\(article.objectID)•") //articleId
                valueBuilder.append("Recommended based on your subscription to \(article.mainTheme ?? "")•") //text
                valueBuilder.append("\(title ?? "")•") //title
                valueBuilder.append("\(source ?? "")•") //source
                valueBuilder.append("\(imageUrl ?? "")•") //imageUrl
                valueBuilder.append("\(article.mainTheme ?? "")•") //theme
                valueBuilder.append("\(pubDate)•") //extra
                valueBuilder.append(now) //timestamp
                
                notificationsDict[key] = valueBuilder.toString()
                
                let notification = UNMutableNotificationContent()
                notification.title = title ?? ""
                notification.body = (source != nil && source != "") ? "\(source ?? "") • \(article.mainTheme ?? "")" : article.mainTheme ?? ""
                notification.sound = UNNotificationSound.default()
                notification.userInfo["type"] = "recArticlesLocal"
                notification.userInfo["articleId"] = article.objectID
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
