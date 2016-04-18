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
    
    static let sharedInstance = Users()
    
    var ref = Firebase(url:"https://real-time-running.firebaseio.com/users")
    var list = [User]()
    var events = EventManager()
    
    init() {
        
        self.observeEvents()
        
    }
    
    func createUser(email: String, password: String, callback: (data: NSDictionary) -> Void) {
        
        ref.createUser(email, password: password, withValueCompletionBlock: { error, result in
            if error != nil {
                print(error)
            } else {
                print("User Created!", result["uid"])
                callback(data: result)
            }
        })
        
    }
    
    func authenticateUserUsingEmail(email: String, password: String, callback: (data: NSDictionary) -> Void) {
        
        ref.authUser(email, password: password, withCompletionBlock: { error, authData in
            if error != nil {
                print("Authentication Failed! \(error.localizedDescription)")
            } else {
                print("User Authenticated!", authData.uid)
                var data = authData.providerData
                data["id"] = authData.uid
                callback(data: data)
            }
        })
        
    }
    
    func authenticateUserUsingFacebook(token: String, callback: (data: NSDictionary) -> Void) {
        
        ref.authWithOAuthProvider("facebook", token: token, withCompletionBlock: { error, authData in
            if error != nil {
                print("Authentication Failed! \(error.description)")
            } else {
                print("User Authenticated!", authData.providerData["id"]!)
                callback(data: authData.providerData)
            }
        })
        
    }
    
    func observeEvents() {
        
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
            self.sort()
            NSNotificationCenter.defaultCenter().postNotificationName("usersSubscriptionReady", object: nil)
        })
        
    }
    
    func sort() {
        
        self.list.sortInPlace({ $0.0.points > $0.1.points })
        
    }
    
    func index(id: String) -> Int? {
        
        self.sort()
        return self.list.indexOf({ $0.id == id })
        
    }
    
    func findOne(id: String) -> User? {
        
        if let index = self.index(id) {
            return self.list[index]
        } else {
            return nil
        }
        
    }
    
    private func documentWasAdded(id: String, fields: NSDictionary?) {
        
        let user = User(id: id, fields: fields)
        self.list.append(user)
        
    }
    
    private func documentWasChanged(id: String, fields: NSDictionary?) {
        
        if let index = self.index(id) {
            
            var user = self.list[index]
            
            user.update(fields)
            self.list[index] = user
            self.sort()

            self.events.trigger("usersUpdated")
            
        }

    }
    
    private func documentWasRemoved(id: String, fields: NSDictionary?) {
        
        if let index = self.index(id) {
            self.list.removeAtIndex(index)
        }
        
    }
    
    func insert(id: String, fields: NSDictionary?, callback: () -> Void) {
        
        if let username = fields?["username"], let email = fields?["email"], let image = fields?["image"], let points = fields?["points"] {
            
            let parameters = [
                "username": username,
                "email": email,
                "image": image,
                "points": points
            ]

            ref.childByAppendingPath(id).setValue(parameters, withCompletionBlock: { (error: NSError?, ref: Firebase!) in
                if error != nil {
                    print("INSERT ERROR:", error)
                    return
                }
                callback()
            })
            
        }
        
    }
    
    func update(id: String, fields: NSDictionary?) {
        
        if let rank = fields?.valueForKey("rank") as? Int {
            self.ref.childByAppendingPath("\(id)/rank").setValue(rank)
        }
        
        if let points = fields?.valueForKey("points") as? Int {
            
            self.ref.childByAppendingPath("\(id)/points").runTransactionBlock({
                (currentData:FMutableData!) in
                var value = currentData.value as? Int
                if value == nil {
                    value = 0
                }
                currentData.value = value! + points
                return FTransactionResult.successWithValue(currentData)
            })
            
        }
        
    }

}