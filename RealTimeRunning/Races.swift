//
//  Races.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 21/03/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import Foundation
import SwiftDDP

class Races: AbstractCollection {
    
    var races = [Race]()
    
    var sorted: [Race] {
        return Array(self.races).sort({
            if let first = $0.createdAt, let second = $1.createdAt {
                return first.compare(second) == .OrderedAscending
            } else {
                return false
            }
        })
    }
    
    var count: Int {
        
        return self.races.count
        
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

    override internal func documentWasAdded(collection: String, id: String, fields: NSDictionary?) {
        
        let race = Race(id: id, fields: fields)
        
        self.races.append(race)
        
        NSNotificationCenter.defaultCenter().postNotificationName("reloadRaces", object: nil)
        
    }
    
    override internal func documentWasChanged(collection: String, id: String, fields: NSDictionary?, cleared: [String]?) {
        
        if let index = races.indexOf({ $0.id == id }) {
            
            var race = self.races[index]
            
            race.update(fields)
            
            self.races[index] = race
            
            NSNotificationCenter.defaultCenter().postNotificationName("raceUpdated", object: race.id)
            
        }
    }
    
    override internal func documentWasRemoved(collection: String, id: String) {
        
        if let index = races.indexOf({ $0.id == id }) {
            
            self.races.removeAtIndex(index)
            
        }
        
    }
    
}