//
//  ShareUtils.swift
//  Acorn
//
//  Created by macOS on 1/1/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import Foundation
import Firebase

class ShareUtils {
    static func createShareUri(articleId: String, url: String, sharerId: String) -> String {
        var cleanedUrl: String
        
        if url.starts(with: "http://") {
            cleanedUrl = String(url[url.index(url.startIndex, offsetBy: 7)...])
        } else if url.starts(with: "https://") {
            cleanedUrl = String(url[url.index(url.startIndex, offsetBy: 8)...])
        } else {
            cleanedUrl = url
        }
        
        return "https://acorncommunity.sg/article?id=\(articleId)&url=\(cleanedUrl)&sharerId=\(sharerId)"
    }
    
    static func createShortDynamicLink(url: String, sharerId: String, onComplete: @escaping (String) -> ()) {
        guard let link = URL(string: url) else { return }
        let dynamicLinksDomain = "https://acorncommunity.sg/share"
        if let builder = DynamicLinkComponents(link: link, domainURIPrefix: dynamicLinksDomain) {
            builder.iOSParameters = DynamicLinkIOSParameters(bundleID: "sg.acorncommunity.acorn")
            builder.iOSParameters?.appStoreID = "1435141923"
            builder.iOSParameters?.minimumAppVersion = "1.2.5"
            builder.iOSParameters?.fallbackURL = link
            
            builder.androidParameters = DynamicLinkAndroidParameters(packageName: "acorn.com.acorn_app")
            builder.androidParameters?.minimumVersion = 46
            builder.androidParameters?.fallbackURL = link
            
            builder.analyticsParameters = DynamicLinkGoogleAnalyticsParameters(source: sharerId, medium: "share", campaign: "")
            
            builder.options = DynamicLinkComponentsOptions()
            builder.options?.pathLength = ShortDynamicLinkPathLength.short
            
            builder.shorten { (url, warnings, error) in
                if let error = error {
                    print(error)
                }
                guard let dynamicLink = url, error == nil else { return }
                onComplete(dynamicLink.absoluteString)
            }
        }
    }
}
