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
    var startTime: NSDate
    var competitors: [JSON]?
    var distance: Int
    
    init(id: String, startTime: NSDate, competitors: [JSON]?, distance: Int) {
        
        self.id = id
        self.startTime = startTime
        self.competitors = competitors
        self.distance = distance
        
        // super.init()
        
    }

    
}
