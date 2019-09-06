//
//  NSRange+StringIndex.swift
//  Acorn
//
//  Created by Jeremy Ling on 3/9/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import Foundation

public extension NSRange {
    private init(string: String, lowerBound: String.Index, upperBound: String.Index) {
        let utf16 = string.utf16
        
        let lowerBound = lowerBound.samePosition(in: utf16)
        let location = utf16.distance(from: utf16.startIndex, to: lowerBound!)
        let length = utf16.distance(from: lowerBound!, to: upperBound.samePosition(in: utf16)!)
        
        self.init(location: location, length: length)
    }
    
    init(range: Range<String.Index>, in string: String) {
        self.init(string: string, lowerBound: range.lowerBound, upperBound: range.upperBound)
    }
    
    init(range: ClosedRange<String.Index>, in string: String) {
        self.init(string: string, lowerBound: range.lowerBound, upperBound: range.upperBound)
    }
}
