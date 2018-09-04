//
//  Theme.swift
//  Acorn
//
//  Created by macOS on 14/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit

class Theme: NSObject {
    var name: String
    var isSelected: Bool
    
    init(name: String, isSelected: Bool) {
        self.name = name
        self.isSelected = isSelected
        super.init()
    }
}
