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
    
    func getStartTime(index: Int) -> String {
        
        let components = NSCalendar.currentCalendar().components([.Day, .Month, .Year, .Hour, .Minute, .Second ], fromDate: NSDate())
        components.minute = 0
        components.second = 0
        let startDate = NSCalendar.currentCalendar().dateFromComponents(components)
        
        components.setValue(index + 1, forComponent: .Hour)
        let startTime = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: startDate!, options: NSCalendarOptions(rawValue: 0))
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        let date = dateFormatter.stringFromDate(startTime!)
        
        return date
        
    }

}
