//
//  Competitor.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 10/03/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

struct Competitor {
    
    var id: String
    var username: String?
    var imageURL: String?
    var distance: Double = 0.0
    var pace: String = ""
    var image: UIImage? {
        if let string = self.imageURL, let nsurl = NSURL(string: string), let data = NSData(contentsOfURL: nsurl), let image = UIImage(data: data) {
            return image
        } else {
            return nil
        }
    }
    
    init(id: String, fields: NSDictionary?) {
        
        self.id = id
        self.update(fields)
        
    }
    
    mutating func update(fields: NSDictionary?) {
        
        if let username = fields?.valueForKey("username") as? String {
            
            self.username = username
            
        }
        
        if let image = fields?.valueForKey("image") as? String {
            
            self.imageURL = image
            
        }
        
        if let distance = fields?.valueForKey("distance") as? Double {
            
            self.distance = distance
            
        }
        
        if let pace = fields?.valueForKey("pace") as? Double {
            
            self.setPace(pace)
            
        }
        
    }
    
    mutating func setPace(pace: Double) {
        
        let paceStr = String(pace * 16.6667)
        let paceArr = paceStr.componentsSeparatedByString(".")
        let minutes = paceArr[0]
        let seconds = String(paceArr[1].characters.prefix(2))
        
        self.pace = "\(minutes)'\(seconds)\"/km"
        
    }
    
}
