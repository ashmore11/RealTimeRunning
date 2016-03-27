//
//  Race.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 18/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import Foundation
import EmitterKit

struct Race {
    
    var id: String?
    var createdAt: NSDate?
    var competitors: [String: AnyObject]?
    var distance: Int?
    var live: Bool?
    
    init(id: String, fields: NSDictionary?) {
        
        self.id = id
        self.update(fields)
        
    }
    
    mutating func update(fields: NSDictionary?) {
        
        if let createdAt = fields?.valueForKey("createdAt") as? String {
            
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            let date = formatter.dateFromString(createdAt)
            
            self.createdAt = date
            
        }
        
        if let competitors = fields?.valueForKey("competitors") as? [String: AnyObject] {
            
            self.competitors = competitors
            
        }
        
        if let distance = fields?.valueForKey("distance") as? Int {
            
            self.distance = distance
            
        }
        
        if let live = fields?.valueForKey("live") as? Bool {
            
            self.live = live
            
        }
        
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
