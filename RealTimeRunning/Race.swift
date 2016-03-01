//
//  Races.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 18/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import SwiftyJSON

class Race {
    
    // MARK: Properties
    
    var id: String
    var createdAt: NSDate
    var competitors: [JSON]?
    var distance: Int
    var live: Bool
    var startTime: String?
    var index: Int
    
    init(id: String, createdAt: NSDate, competitors: [JSON]?, distance: Int, live: Bool, index: Int) {
        
        self.id = id
        self.createdAt = createdAt
        self.competitors = competitors
        self.distance = distance
        self.live = live
        self.index = index
        
    }

}
