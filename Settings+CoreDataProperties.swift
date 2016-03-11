//
//  Settings+CoreDataProperties.swift
//  
//
//  Created by bob.ashmore on 11/03/2016.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Settings {

    @NSManaged var displayUnits: String?
    @NSManaged var loggingFrequency: NSNumber?

}
