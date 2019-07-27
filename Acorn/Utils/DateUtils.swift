//
//  DateUtils.swift
//  Acorn
//
//  Created by macOS on 5/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation

class DateUtils {
    static func parsePrettyDate(unixTimestamp: Double) -> String {
        let dateFormat = DateFormatter()
        dateFormat.locale = Locale(identifier: "en_SG")
        dateFormat.dateFormat = "d MMM"
        dateFormat.timeZone = TimeZone(identifier: TimeZone.current.identifier)
        
        let now = Double(Date().timeIntervalSince1970)
        let diff = now - unixTimestamp / 1000.0
        
        let diffSeconds = Int(round(diff))
        let diffMinutes = Int(round(diff / 60.0))
        let diffHours = Int(round(diff / (60.0 * 60.0)))
        
        if diff < 0 {
            return ""
        } else if diffSeconds < 60 {
            return "\(diffSeconds)s ago"
        } else if diffMinutes < 60 {
            return "\(diffMinutes)m ago"
        } else if diffHours < 24 {
            return "\(diffHours)h ago"
        } else {
            let date = Date(timeIntervalSince1970: unixTimestamp / 1000.0)
            return dateFormat.string(from: date)
        }
    }
    
    static func hoursSince(unixTimestamp: Double) -> Int {
        let dateFormat = DateFormatter()
        dateFormat.locale = Locale(identifier: "en_SG")
        dateFormat.timeZone = TimeZone(identifier: TimeZone.current.identifier)
        
        let now = Double(Date().timeIntervalSince1970)
        let diff = now - unixTimestamp / 1000.0
        let diffHours = Int(floor(diff / (60 * 60)))
        
        return diffHours
    }
    
    static func parseCommentDate(unixTimestamp: Double) -> String {
        let dateAtMidnight = getThisMidnight()
        
        let dateFormat = DateFormatter()
        dateFormat.locale = Locale(identifier: "en_SG")
        dateFormat.dateFormat = "dd MMM"
        dateFormat.timeZone = TimeZone(identifier: TimeZone.current.identifier)
        
        let timeFormat = DateFormatter()
        timeFormat.locale = Locale(identifier: "en_SG")
        timeFormat.dateFormat = "HH:mm"
        timeFormat.timeZone = TimeZone(identifier: TimeZone.current.identifier)
        
        let date = Date(timeIntervalSince1970: unixTimestamp / 1000.0)
        if unixTimestamp >= dateAtMidnight {
            return timeFormat.string(from: date)
        } else {
            return dateFormat.string(from: date)
        }
    }
    
    static func getThisMidnight() -> Double {
        var calendar = NSCalendar.current
        calendar.locale = Locale(identifier: "en_SG")
        calendar.timeZone = TimeZone(identifier: TimeZone.current.identifier)!
        let dateAtMidnight = calendar.startOfDay(for: Date()).timeIntervalSince1970 * 1000.0
        return dateAtMidnight
    }
    
    static func getNextMidnight() -> Double {
        return getThisMidnight() + (24.0 * 60.0 * 60.0 * 1000.0)
    }
    
    static func getFollowingMidnight() -> Double {
        return getNextMidnight() + (24.0 * 60.0 * 60.0 * 1000.0)
    }
    
    static func getThreeDaysAgoMidnight() -> Double {
        return getThisMidnight() - (3.0 * 24.0 * 60.0 * 60.0 * 1000.0)
    }
    
    static func getThirtyDaysLaterMidnight() -> Double {
        return getThisMidnight() + (30.0 * 24.0 * 60.0 * 60.0 * 1000.0)
    }
    
    static func getThirtyDaysAgoMidnight() -> Double {
        return getThisMidnight() - (30.0 * 24.0 * 60.0 * 60.0 * 1000.0)
    }
    
    static func getFourteenDaysAgoMidnight() -> Double {
        return getThisMidnight() - (14.0 * 24.0 * 60.0 * 60.0 * 1000.0)
    }
    
    static func getWeekAgoMidnight() -> Double {
        return getThisMidnight() - (7.0 * 24.0 * 60.0 * 60.0 * 1000.0)
    }
    
    static func getWeekLaterMidnight() -> Double {
        return getThisMidnight() + (7.0 * 24.0 * 60.0 * 60.0 * 1000.0)
    }
}
