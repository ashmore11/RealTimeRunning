//
//  ErrorLogTableViewController.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 03/03/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import CoreData

class ErrorLogTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var managedObjectContext: NSManagedObjectContext!
    
    lazy var fetchedResultsController: NSFetchedResultsController? = {
        if let context = self.managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: "ErrorLog")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "logDate", ascending: true)]
            
            let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            frc.delegate = self
            return frc
        }
        return nil
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIColor.blackColor()
        
        self.title = "Error Log"
        
        let newButton  = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(ErrorLogTableViewController.processAction))
        navigationItem.rightBarButtonItem = newButton

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
        let cell = tableView.dequeueReusableCellWithIdentifier("errorLogCell", forIndexPath: indexPath) as! ErrorLogTableViewCell
        self.configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    func configureCell(cell:ErrorLogTableViewCell, indexPath:NSIndexPath) {
        // Configure the cell...
        setTableViewBackgroundGradient(cell, topColor: UIColor(red: 0.133, green: 0.133, blue: 0.133, alpha: 1), bottomColor: UIColor.blackColor())
        
        if let errdetail = fetchedResultsController?.objectAtIndexPath(indexPath) as? ErrorLog {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "d MMM y   HH:m:s"
            var formattedDate = "Unset"
            var logMessage = "Unset"
            if let logDate = errdetail.logDate {
                formattedDate = dateFormatter.stringFromDate(logDate) // if date conversion fails this returns nil and that's OK
            }
            if let message = errdetail.logMessage {
                logMessage = message
            }
            cell.dateLabel!.text = String(format:"%@",formattedDate)
            cell.dateLabel!.textColor = UIColor.whiteColor()
            cell.logLabel!.text = String(format:"Log Entry: %@",logMessage)
            cell.logLabel!.textColor = UIColor.whiteColor()
            cell.logLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
            // Dont show any cell selection but still allow the user to delete a cell
            cell.selectionStyle = .None
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Make the seperator lines between cells go all the way to the view's left edge
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layoutMargins = UIEdgeInsetsZero
        cell.separatorInset = UIEdgeInsetsZero
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
            let object = fetchedResultsController!.objectAtIndexPath(indexPath) as! ErrorLog
            managedObjectContext.deleteObject(object)
            do {
                try managedObjectContext.save()
            } catch let error as NSError {
                print("Error saving context after delete: \(error.localizedDescription)")
            }
        default:break
        }
    }
    
    func processAction(sender: AnyObject) {
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            delegate.removeEntityData("ErrorLog")
            fetchedResultsController = nil
            //NSFetchedResultsController.deleteCacheWithName("ErrorLogCache")
            do {
                try fetchedResultsController?.performFetch()
            } catch {
                print("An error occurred")
            }
            tableView.reloadData()
        }

    }


}
