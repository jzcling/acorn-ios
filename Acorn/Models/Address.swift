//
//  Address.swift
//  Acorn
//
//  Created by Jeremy Ling on 20/6/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import Foundation
import FirebaseUI
import Firebase

class Address {
    var objectID: String
    var article: [String: Double] = [String: Double]()
    var address: String
    var formattedAddress: String?
    var location: [String: Double] = [String: Double]()
    
    init(snapshot: DataSnapshot) {
        let value = snapshot.value as! [String: Any]
        self.objectID = value["objectID"] as! String
        self.article = value["article"] as? [String: Double] ?? [String: Double]()
        self.address = value["address"] as! String
        self.formattedAddress = value["formattedAddress"] as? String
        self.location = value["location"] as? [String: Double] ?? [String: Double]()
    }
    
    init(json: [String: Any]) {
        let value = json
        self.objectID = value["objectID"] as! String
        self.article = value["article"] as? [String: Double] ?? [String: Double]()
        self.address = value["address"] as! String
        self.formattedAddress = value["formattedAddress"] as? String
        self.location = value["location"] as? [String: Double] ?? [String: Double]()
    }
}
