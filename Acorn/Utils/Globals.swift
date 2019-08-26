//
//  Globals.swift
//  Acorn
//
//  Created by Jeremy Ling on 3/8/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import UIKit

class Globals {
    static let instance = Globals()
    var token: String?
    var isUserEmailVerified: Bool = false
    var hasOpenedArticle: Bool = false
}
