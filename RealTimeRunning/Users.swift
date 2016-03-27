//
//  Users.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 22/03/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import Foundation
import Firebase
import SwiftyJSON

class Users {
    
    var ref = Firebase(url:"https://real-time-running.firebaseio.com/users")
    var users = [User]()
    
    init() {
        
        ref.observeEventType(.ChildAdded, withBlock: { snapshot in
            if let id = snapshot?.key, let value = snapshot?.value, let fields = JSON(value).dictionaryObject {
                self.documentWasAdded(id, fields: fields)
            }
        })
        
        ref.observeEventType(.ChildChanged, withBlock: { snapshot in
            if let id = snapshot?.key, let value = snapshot?.value, let fields = JSON(value).dictionaryObject {
                self.documentWasChanged(id, fields: fields)
            }
        })
        
        ref.observeEventType(.ChildRemoved, withBlock: { snapshot in
            if let id = snapshot?.key, let value = snapshot?.value, let fields = JSON(value).dictionaryObject {
                self.documentWasRemoved(id, fields: fields)
            }
        })
        
        ref.observeSingleEventOfType(.Value, withBlock: { snapshot in
            NSNotificationCenter.defaultCenter().postNotificationName("usersSubscriptionReady", object: nil)
        })
        
    }
    
    func index(id: String) -> Int? {
        
        return self.users.indexOf({ $0.fbid == id })
        
    }
    
    func findOne(id: String) -> User? {
        
        if let index = self.index(id) {
            
            return self.users[index]
            
        } else {
            
            return nil
            
        }
        
    }
    
    private func documentWasAdded(id: String, fields: NSDictionary?) {
        
        let user = User(id: id, fields: fields)
        
        self.users.append(user)
        
    }
    
    private func documentWasChanged(id: String, fields: NSDictionary?) {
        
        if let index = self.index(id) {
            
            var user = self.users[index]
            
            user.update(fields)
            
            self.users[index] = user
            
        }

    }
    
    private func documentWasRemoved(id: String, fields: NSDictionary?) {
        
        if let index = self.index(id) {
            
            self.users.removeAtIndex(index)
            
        }
        
    }
    
    func insert(id: String, fields: NSDictionary?, callback: (User) -> Void) {
        
        if let name = fields?["name"], let email = fields?["email"], let imageURL = fields?["image"] {
            
            let parameters = [
                "fbid": id,
                "name": name,
                "email": email,
                "image": imageURL
            ]
            
            let user = User(id: id, fields: parameters)

            let userRef = ref.childByAutoId()
            userRef.setValue(parameters, withCompletionBlock: { (error: NSError?, ref: Firebase!) in
            
                if error != nil {
                    print("INSERT ERROR:", error)
                    return
                }

                self.users.append(user)
                
                callback(user)
            
            })
            
        }
        
    }

}