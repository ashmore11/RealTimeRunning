//
//  Races.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 21/03/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import Firebase
import SwiftyJSON
import FBSDKCoreKit

class Races {
    
    static let sharedInstance = Races()
    
    var events = EventManager()
    var ref = Firebase(url:"https://real-time-running.firebaseio.com/races")
    var races = [Race]()
    var sorted: [Race] {
        return self.races.sort({ $0.createdAt?.compare($1.createdAt!) == .OrderedAscending })
    }
    var count: Int {
        return self.races.count
    }
    
    init() {
        
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
            self.events.trigger("collectionReady")
        })
        
    }
    
    func index(id: String) -> Int? {
        
        return self.sorted.indexOf({ $0.id == id })
        
    }
    
    func findOne(id: String) -> Race? {
    
        if let index = self.index(id) {
            return self.races[index]
        } else {
            return nil
        }
    
    }

    private func documentWasAdded(id: String, fields: NSDictionary?) {
        
        let race = Race(id: id, fields: fields)
        self.races.append(race)
        
    }
    
    private func documentWasChanged(id: String, fields: NSDictionary?) {
        
        if let index = self.index(id) {
            
            var race = self.races[index]
            race.update(fields)
            self.races[index] = race
            
            NSNotificationCenter.defaultCenter().postNotificationName("raceUpdated", object: race.id)
        
        }
        
    }
    
    private func documentWasRemoved(id: String, fields: NSDictionary?) {
        
        if let index = self.index(id) {
            self.races.removeAtIndex(index)
        }
        NSNotificationCenter.defaultCenter().postNotificationName("reloadRaces", object: nil)
        
    }
    
}