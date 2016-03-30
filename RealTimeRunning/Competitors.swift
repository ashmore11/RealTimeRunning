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
    var competitors = [Competitor]()
    let events = EventManager()
    var sorted: [Competitor] {
        return self.competitors.sort({ $0.distance > $1.distance })
    }
    var count: Int {
        return self.competitors.count
    }
    
    init(raceId: String) {
        
        self.ref = Firebase(url: "https://real-time-running.firebaseio.com/races/\(raceId)/competitors")
        
        self.observeEvents()
        
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
            NSNotificationCenter.defaultCenter().postNotificationName("competitorsReady", object: nil)
        })
        
    }
    
    func index(id: String) -> Int? {
        
        return self.sorted.indexOf({ $0.id == id })
        
    }
    
    func findOne(id: String) -> Competitor? {
        
        if let index = self.index(id) {
            
            return self.competitors[index]
            
        } else {
            
            return nil
            
        }
        
    }
    
    private func documentWasAdded(id: String, fields: NSDictionary?) {
            
        let competitor = Competitor(id: id, fields: fields)
        
        self.competitors.append(competitor)
        
        if let index = self.index(id) {
            
            let object = [
                "index": index,
                "insert": true
            ]
            
            self.events.trigger("competitorsUpdated", information: object)
        
        }
        
    }
    
    private func documentWasChanged(id: String, fields: NSDictionary?) {
        
        if let index = self.index(id) {
            
            var competitor = self.competitors[index]
            
            competitor.update(fields)
            
            self.competitors[index] = competitor
            
        }
        
        self.events.trigger("reloadCompetitorsTableview")
        
    }
    
    private func documentWasRemoved(id: String, fields: NSDictionary?) {
        
        if let index = self.index(id) {
            
            self.competitors.removeAtIndex(index)
            
            let object = [
                "index": index,
                "insert": false
            ]
            
            self.events.trigger("competitorsUpdated", information: object)
            
        }
        
    }
    
    func insert(id: String) {
        
        if let user = self.users.findOne(id), let name = user.name, let image = user.image {
            
            let fields = [
                "name": name,
                "image": image,
                "distance": 0,
                "pace": 0
            ]
            
            self.ref.childByAppendingPath(id).setValue(fields)
            
        }
        
    }
    
    func remove(id: String) {
        
        self.ref.childByAppendingPath(id).removeValue()
        
    }
    
    func update(id: String, fields: NSDictionary?) {
        
        if let distance = fields?.valueForKey("distance"), let pace = fields?.valueForKey("pace") {
            
            self.ref.childByAppendingPath("\(id)/distance").setValue(distance)
            self.ref.childByAppendingPath("\(id)/pace").setValue(pace)
            
        }
        
    }
    
}