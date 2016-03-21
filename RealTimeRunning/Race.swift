//
//  Race.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 18/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import SwiftDDP
import SwiftyJSON

class Race: MeteorDocument {
    
    var createdAt: NSDate?
    var competitors: [String]?
    var distance: Int = 20
    var live: Bool = false
    var startTime: String?
    
    override func update(fields: NSDictionary?, cleared: [String]?) {
        
        if let data = fields?.valueForKey("competitors"), let newCompetitors = JSON(data).arrayObject as? [String], let oldCompetitors = self.competitors {
            
            let nc = Set(newCompetitors)
            let oc = Set(oldCompetitors)
            
            let insert = nc.count > oc.count ? true : false
            
            if let raceId = self.valueForKey("_id"), let userId = nc.exclusiveOr(oc).first {
            
                let object = [
                    "raceId": raceId,
                    "userId": userId,
                    "insert": insert
                ]
                
                super.update(fields, cleared: cleared)
                
                NSNotificationCenter.defaultCenter().postNotificationName("raceUpdated", object: object)
        
            }
            
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
