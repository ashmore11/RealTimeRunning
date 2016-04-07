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
    var name: String?
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
        
    func sendRequest() {
        
        if let accessToken = FBSDKAccessToken.currentAccessToken() {
            
            let parameters = ["fields": "email, first_name, last_name, picture.type(large)"]
            let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: parameters, tokenString: accessToken.tokenString, version: nil, HTTPMethod: "GET")
            
            graphRequest.startWithCompletionHandler { (connection, result, error) -> Void in
                
                if error != nil {
                    logError(error.localizedDescription)
                    return
                }
                
                self.getData(result)
                
            }
            
        }
        
    }
    
    func getData(data: AnyObject) {
        
        guard let id = data.objectForKey("id") as? String else { return }
        
        self.id = id
        
        if let firstName = data.objectForKey("first_name") as? String {
            self.name = firstName
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