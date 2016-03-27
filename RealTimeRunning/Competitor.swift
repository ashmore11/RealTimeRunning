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
    var image: UIImage?
    var name: String?
    var position: String = ""
    var distance: Double = 0.0
    var pace: String = ""
    
    init(id: String, fields: NSDictionary?) {
        
        self.id = id
        self.update(fields)
        
    }
    
    mutating func setNameAndImage(name: String, image: UIImage) {
        
        self.name = name
        self.image = image
        
    }
    
    mutating func update(fields: NSDictionary?) {
        
        if let position = fields?.valueForKey("position") as? Int {
            
            self.setPosition(position)
            
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
    
    mutating func setPosition(index: Int) {
        
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .OrdinalStyle
        
        if let position = formatter.stringFromNumber(index + 1) {
        
            self.position = self.distance > 0.0 ? position : ""
            
        }
        
    }
    
}
