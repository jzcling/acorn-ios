//
//  MrtStation.swift
//  Acorn
//
//  Created by Jeremy Ling on 20/6/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import Foundation
import FirebaseUI
import Firebase

class MrtStation {
    var geofence: Bool
    var latitude: Double
    var longitude: Double
    var objectID: String
    var stationLocale: String?
    var stationName: String?
    var stationNumber: String?
    var type: String
    
    init(snapshot: DataSnapshot) {
        let value = snapshot.value as! [String: Any]
        self.geofence = value["geofence"] as? Bool ?? false
        self.latitude = value["latitude"] as! Double
        self.longitude = value["longitude"] as! Double
        self.objectID = value["objectID"] as! String
        self.stationLocale = value["stationLocale"] as? String
        self.stationName = value["stationName"] as? String
        self.stationNumber = value["stationNumber"] as? String
        self.type = value["type"] as! String
    }
    
    init(json: [String: Any]) {
        let value = json
        self.geofence = value["geofence"] as? Bool ?? false
        self.latitude = value["latitude"] as! Double
        self.longitude = value["longitude"] as! Double
        self.objectID = value["objectID"] as! String
        self.stationLocale = value["stationLocale"] as? String
        self.stationName = value["stationName"] as? String
        self.stationNumber = value["stationNumber"] as? String
        self.type = value["type"] as! String
    }
}
