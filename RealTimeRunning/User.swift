//
//  User.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 18/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import SwiftDDP

class User: MeteorDocument {
    
    var id: String?
    var name: String?
    var image: String?
    
    required init(id: String, fields: NSDictionary?) {
        
        super.init(id: id, fields: fields)
        
        self.id = id
        
    }
    
    func getImage() -> UIImage? {
        
        if let string = self.image, let nsurl = NSURL(string: string), let data = NSData(contentsOfURL:nsurl), let image = UIImage(data:data) {
         
            return image
            
        } else {
            
            return nil
            
        }
        
    }
    
}
