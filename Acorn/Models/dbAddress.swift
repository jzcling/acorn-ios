//
//  dbAddress.swift
//  Acorn
//
//  Created by Jeremy Ling on 3/9/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import Foundation
import FirebaseUI
import Firebase

class dbAddress: Codable {
    var objectID: String
    var articleId: String
    var address: String
    var formattedAddress: String?
    var latitude: Double
    var longitude: Double
    
    init(address: Address, articleId: String) {
        self.objectID = address.objectID
        self.articleId = articleId
        self.address = address.address
        self.formattedAddress = address.formattedAddress
        self.latitude = address.location["lat"]!
        self.longitude = address.location["lng"]!
    }
    
    init(objectID: String, articleId: String, address: String, formattedAddress: String?, latitude: Double, longitude: Double) {
        self.objectID = objectID
        self.articleId = articleId
        self.address = address
        self.formattedAddress = formattedAddress
        self.latitude = latitude
        self.longitude = longitude
    }
}
