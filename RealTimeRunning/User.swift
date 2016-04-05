//
//  User.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 18/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

struct User {
    
    var id: String?
    var username: String?
    var name: String?
    var image: String?
    
    init(id: String, fields: NSDictionary?) {
        
        self.id = id
        self.update(fields)
        
    }
    
    mutating func update(fields: NSDictionary?) {
        
        if let username = fields?.valueForKey("username") as? String {
            
            self.username = username
            
        }
        
        if let name = fields?.valueForKey("name") as? String {
        
            self.name = name
        
        }
        
        if let image = fields?.valueForKey("image") as? String {
            
            self.image = image
            
        }
        
    }
    
    func getImage() -> UIImage? {
        
        if let string = self.image, let nsurl = NSURL(string: string), let data = NSData(contentsOfURL:nsurl), let image = UIImage(data:data) {
         
            return image
            
        } else {
            
            return nil
            
        }
        
    }
    
}
