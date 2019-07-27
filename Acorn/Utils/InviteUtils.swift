//
//  InviteUtils.swift
//  Acorn
//
//  Created by Jeremy Ling on 1/7/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import Foundation
import Firebase

class InviteUtils {
    static func createShortDynamicLink(uid: String, onComplete: @escaping (String) -> ()) {
        guard let link = URL(string: "https://acorncommunity.sg/?referrer=\(uid)") else { return }
        let dynamicLinksDomain = "https://acorncommunity.sg/invite"
        if let builder = DynamicLinkComponents(link: link, domainURIPrefix: dynamicLinksDomain) {
            builder.iOSParameters = DynamicLinkIOSParameters(bundleID: "sg.acorncommunity.acorn")
            builder.iOSParameters?.appStoreID = "1435141923"
            builder.iOSParameters?.minimumAppVersion = "1.2.5"
            
            builder.androidParameters = DynamicLinkAndroidParameters(packageName: "acorn.com.acorn_app")
            builder.androidParameters?.minimumVersion = 46
            
            builder.analyticsParameters = DynamicLinkGoogleAnalyticsParameters(source: uid, medium: "invite", campaign: "")
            
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
