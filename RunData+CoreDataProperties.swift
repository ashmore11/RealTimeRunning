//
//  RunData+CoreDataProperties.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 24/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension RunData {

    @NSManaged var lattitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var speed: NSNumber?
    @NSManaged var distance: NSNumber?
    @NSManaged var altitude: NSNumber?
    @NSManaged var stepsTaken: NSNumber?
    @NSManaged var pedDistance: NSNumber?
    @NSManaged var currentPace: NSNumber?
    @NSManaged var currentCadence: NSNumber?
    @NSManaged var floorsAscended: NSNumber?
    @NSManaged var floorsDescended: NSNumber?
    @NSManaged var timeStamp: NSDate?
    @NSManaged var runDataToRunDetail: RunDetail?

}
