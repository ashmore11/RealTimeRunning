//
//  Races.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 18/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

class Race {
    
    // MARK: Properties
    
    var id: String
    var createdAt: NSDate
    var competitors: [String]?
    var distance: Int
    var live: Bool
    var index: Int
    var startTime: String?
    
    init(id: String, createdAt: NSDate, competitors: [String]?, distance: Int, live: Bool, index: Int) {
        
        self.id = id
        self.createdAt = createdAt
        self.competitors = competitors
        self.distance = distance
        self.live = live
        self.index = index
        
    }

}
