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
    var firstName: String?
    var image: String?
    var email: String?
    var rank: Int?
    var points: Int?
    
    init(id: String, fields: NSDictionary?) {
        
        self.id = id
        self.update(fields)
        
    }
    
    mutating func update(fields: NSDictionary?) {
        
        if let username = fields?.valueForKey("username") as? String {
            self.username = username
        }
        
        if let firstName = fields?.valueForKey("firstName") as? String {
            self.firstName = firstName
        }
        
        if let image = fields?.valueForKey("image") as? String {
            self.image = image
        }
        
        if let email = fields?.valueForKey("email") as? String {
            self.email = email
        }
        
        if let rank = fields?.valueForKey("rank") as? Int {
            self.rank = rank
        }
        
        if let points = fields?.valueForKey("points") as? Int {
            self.points = points
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
