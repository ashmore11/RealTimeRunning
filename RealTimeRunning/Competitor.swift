//
//  Competitor.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 10/03/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

class Competitor {
    
    // MARK: Properties
    
    var id: String
    var image: UIImage
    var name: String
    var position: String = ""
    var distance: Double = 0.0
    var pace: String = ""
    
    init(id: String, image: UIImage, name: String) {
        
        self.id = id
        self.image = image
        self.name = name
        
    }
    
    func setDistance(distance: Double) {
        
        self.distance = distance
        
    }
    
    func setPace(pace: Double) {
        
        let paceStr = String(pace * 16.6667)
        let paceArr = paceStr.componentsSeparatedByString(".")
        let minutes = paceArr[0]
        let seconds = String(paceArr[1].characters.prefix(2))
        
        self.pace = "\(minutes)'\(seconds)\"/km"
        
    }
    
    func setPosition(index: Int) {
        
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .OrdinalStyle
        
        if let position = formatter.stringFromNumber(index + 1) {
        
            self.position = self.distance > 0.0 ? position : ""
            
        }
        
    }
    
}
