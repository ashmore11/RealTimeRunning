//
//  Users.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 22/03/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import Foundation
import SwiftDDP

class Users: AbstractCollection {
    
    var users = [User]()
    
    func index(id: String) -> Int? {
        
        return self.users.indexOf({ $0.id == id })
        
    }
    
    func findOne(id: String) -> User? {
        
        if let index = self.index(id) {
            
            return self.users[index]
            
        } else {
            
            return nil
            
        }
        
    }
    
    override internal func documentWasAdded(collection: String, id: String, fields: NSDictionary?) {
        
        let user = User(id: id, fields: fields)
        
        self.users.append(user)
        
    }
    
    override internal func documentWasChanged(collection: String, id: String, fields: NSDictionary?, cleared: [String]?) {
        
        if let index = self.index(id) {
            
            var user = self.users[index]
            
            user.update(fields)
            
            self.users[index] = user
            
        }
    }
    
    override internal func documentWasRemoved(collection: String, id: String) {
        
        if let index = self.index(id) {
            
            self.users.removeAtIndex(index)
            
        }
        
    }
    
    func insert(id: String, fields: NSDictionary?, callback: (User) -> Void) {
        
        if let name = fields?["name"], let email = fields?["email"], let imageURL = fields?["image"] {
            
            let parameters = [
                "id": id,
                "name": name,
                "email": email,
                "image": imageURL
            ]
            
            let user = User(id: id, fields: parameters)
            
            Meteor.call("createUser", params: [id, name, email, imageURL]) { result, error in
                
                if error != nil {
                    print("INSERT ERROR:", error)
                    return
                }
                
                self.users.append(user)
                
                callback(user)
                
            }
            
        }
        
        
        
    }
    
}