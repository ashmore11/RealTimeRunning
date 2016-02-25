//
//  RunDetail+CoreDataProperties.swift
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

extension RunDetail {

    @NSManaged var name: String?
    @NSManaged var date: NSDate?
    @NSManaged var distance: NSNumber?
    @NSManaged var organiser: String?
    @NSManaged var contact: String?
    @NSManaged var startLat: NSNumber?
    @NSManaged var startLon: NSNumber?
    @NSManaged var runDetailToRunData: NSOrderedSet?

}
