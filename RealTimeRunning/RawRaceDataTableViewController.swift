//
//  RawRaceDataTableViewController.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 24/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class RawRaceDataTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    var managedObjectContext: NSManagedObjectContext!
    var runDetail:RunDetail?
    
    lazy var fetchedResultsController: NSFetchedResultsController? = {
        if self.runDetail == nil {
            return nil
        }
        if let context = self.managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: "RunData")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: true)]
            fetchRequest.predicate = NSPredicate(format:"runDataToRunDetail = %@", self.runDetail!)
            
            let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            frc.delegate = self
            return frc
        }
        return nil
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIColor.blackColor()

        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            self.managedObjectContext = delegate.managedObjectContext
        }
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("An error occurred")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchedResultsController?.sections {
            return sections.count
        }
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("rawRaceCell", forIndexPath: indexPath) as! RawTableViewCell
        self.configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    func configureCell(cell:RawTableViewCell, indexPath:NSIndexPath) {
        // Configure the cell...
        if let rundata = fetchedResultsController?.objectAtIndexPath(indexPath) as? RunData {
            cell.latLonLabel.text = formatLatLonPrintA(CLLocationCoordinate2DMake(Double(rundata.lattitude!), Double(rundata.longitude!)) , type: .degreeDecimalMinutes)
            cell.gpsDataLabel.text = String(format:"Speed:%6.2f Kph Distance:%6.2f",Double(rundata.speed!) * 3.6, Double(rundata.distance!))
            cell.pedometerDataLabel.text = String(format:"Steps:%d Pace:%6.2f Altitude:%6.2f",Int(rundata.stepsTaken!), Double(rundata.currentPace!),Double(rundata.altitude!))
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    // Make the seperator lines between cells go all the way to the view's left edge
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layoutMargins = UIEdgeInsetsZero
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.layoutMargins = UIEdgeInsetsZero
    }
    
    // MARK: - Fetched Results Controller Delegate Methods
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        default: break
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        default: break
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            let movie = fetchedResultsController!.objectAtIndexPath(indexPath) as! RunData
            managedObjectContext.deleteObject(movie)
            do {
                try managedObjectContext.save()
            } catch let error as NSError {
                print("Error saving context after delete: \(error.localizedDescription)")
            }
        default:break
        }
    }
    
}
