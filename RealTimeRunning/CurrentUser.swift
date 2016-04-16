//
//  UserData.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 18/03/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import FBSDKCoreKit

class CurrentUser {
    
    static let sharedInstance = CurrentUser()
    
    let users: Users = Users.sharedInstance
    let events: EventManager = EventManager()
    var loggedIn: Bool = false
    
    var id: String?
    var firstName: String?
    var imageURL: String?
    var email: String?
    
    var username: String? {
        if let id = self.id, let user = self.users.findOne(id) {
            return user.username
        } else {
            return nil
        }
    }
    var rank: Int? {
        if let id = self.id, let index = self.users.index(id) {
            return index + 1
        } else {
            return nil
        }
    }
    var points: Int? {
        if let id = self.id, let user = self.users.findOne(id) {
            return user.points
        } else {
            return nil
        }
    }
    
    func setCurrentUser(user: User) {
        
        if let id = user.id, let firstName = user.firstName, let imageURL = user.image, let email = user.email {
            self.id = id
            self.firstName = firstName
            self.imageURL = imageURL
            self.email = email
        }
        
    }
    
    func setData(data: AnyObject) {
        
        guard let id = data.objectForKey("id") as? String else { return }
        
        self.id = id
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(id, forKey: "userId")
        
        if let firstName = data.objectForKey("first_name") as? String {
            self.firstName = firstName
        }
        
        if let imageURL = data.objectForKey("picture")?.objectForKey("data")?.objectForKey("url") as? String {
            self.imageURL = imageURL
        }
        
        if let email = data.objectForKey("email") as? String {
            self.email = email
        }
        
        self.loggedIn = true
        self.events.trigger("userLoaded")
        
    }
    
}