//
//  Competitors.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 27/03/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import Firebase
import SwiftyJSON
import FBSDKCoreKit

class Competitors {
    
    let users: Users = (UIApplication.sharedApplication().delegate as! AppDelegate).users
    var ref: Firebase
    var list = [Competitor]()
    let events = EventManager()
    
    init(raceId: String) {
        
        self.ref = Firebase(url: "https://real-time-running.firebaseio.com/races/\(raceId)/competitors")
        
        self.observeEvents()
        
    }
    
    func index(id: String) -> Int? {
        
        return self.list.indexOf({ $0.id == id })
        
    }
    
    func findOne(id: String) -> Competitor? {
        
        if let index = self.index(id) {
            
            return self.list[index]
            
        } else {
            
            return nil
            
        }
        
    }
    
    func getPosition(id: String) -> String {
        
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .OrdinalStyle
        
        if let competitor = self.findOne(id), let index = self.index(id), let position = formatter.stringFromNumber(index + 1) {
            
            return competitor.distance > 0 ? position : ""
            
        } else {
            
            return ""
            
        }
        
    }
    
    private func sort() {
        
        self.list.sortInPlace({ $0.0.distance > $0.1.distance })
        
    }
    
    private func observeEvents() {
        
        self.ref.observeEventType(.ChildAdded, withBlock: { snapshot in
            if let id = snapshot?.key, let value = snapshot?.value, let fields = JSON(value).dictionaryObject {
                self.documentWasAdded(id, fields: fields)
            }
        })
        
        self.ref.observeEventType(.ChildChanged, withBlock: { snapshot in
            if let id = snapshot?.key, let value = snapshot?.value, let fields = JSON(value).dictionaryObject {
                self.documentWasChanged(id, fields: fields)
            }
        })
        
        self.ref.observeEventType(.ChildRemoved, withBlock: { snapshot in
            if let id = snapshot?.key, let value = snapshot?.value, let fields = JSON(value).dictionaryObject {
                self.documentWasRemoved(id, fields: fields)
            }
        })
        
        self.ref.observeSingleEventOfType(.Value, withBlock: { snapshot in
            self.sort()
            self.events.trigger("competitorsReady")
        })
        
    }
    
    private func documentWasAdded(id: String, fields: NSDictionary?) {
            
        let competitor = Competitor(id: id, fields: fields)
        
        self.list.append(competitor)
        
        if let index = self.index(id) {
            
            self.events.trigger("competitorAdded", information: index)
        
        }
        
    }
    
    private func documentWasChanged(id: String, fields: NSDictionary?) {
        
        if let index = self.index(id) {
            
            var competitor = self.list[index]
            
            competitor.update(fields)
            
            self.list[index] = competitor
            
            self.sort()
            
            let fields = [
                "index": index,
                "id": id
            ]
            
            self.events.trigger("competitorUpdated", information: fields)
            
        }
        
    }
    
    private func documentWasRemoved(id: String, fields: NSDictionary?) {
        
        if let index = self.index(id) {
            
            self.list.removeAtIndex(index)
            
            self.events.trigger("competitorRemoved", information: index)
            
        }
        
    }
    
    func insert(id: String) {
        
        if let user = self.users.findOne(id), let username = user.username, let image = user.image {
            
            let fields = [
                "username": username,
                "image": image,
                "distance": 0,
                "pace": 0
            ]
            
            self.ref.childByAppendingPath(id).setValue(fields)
            
        }
        
    }
    
    func update(id: String, fields: NSDictionary?) {
        
        if let distance = fields?.valueForKey("distance"), let pace = fields?.valueForKey("pace") {
            
            self.ref.childByAppendingPath("\(id)/distance").setValue(distance)
            self.ref.childByAppendingPath("\(id)/pace").setValue(pace)
            
        }
        
    }
    
    func remove(id: String) {
        
        self.ref.childByAppendingPath(id).removeValue()
        
    }
    
}