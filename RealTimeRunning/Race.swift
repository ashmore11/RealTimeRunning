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
    
    var startTime: NSDate
    var competitors: [User]?
    var distance: Int
    
    init?(startTime: NSDate, competitors: [User]?, distance: Int) {
        
        self.startTime = startTime
        self.competitors = competitors
        self.distance = distance
        
        // super.init()
        
        if distance == 0 {
            
            return nil
            
        }
        
    }

    
}
