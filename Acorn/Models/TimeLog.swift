//
//  TimeLog.swift
//  Acorn
//
//  Created by Jeremy Ling on 7/8/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import UIKit
import FirebaseUI
import Firebase

class TimeLog {
    var userId: String? = ""
    var itemId: String? = ""
    var openTime: Double? = 0
    var closeTime: Double? = 0
    var activeTime: Double? = 0
    var percentScroll: Double? = 0
    var percentReadTimeActive: Double? = 0
    var type: String? = ""
    
    init() {}
}
