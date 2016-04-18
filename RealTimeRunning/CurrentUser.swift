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
    var loggedIn: Bool = false
    
    var id: String?
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
        
        if let id = user.id, let imageURL = user.image, let email = user.email {
            self.id = id
            self.imageURL = imageURL
            self.email = email
            self.loggedIn = true
            
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(id, forKey: "userId")
        }
        
    }
    
}