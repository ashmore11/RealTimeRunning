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
import MessageUI

class RawRaceDataTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, MFMailComposeViewControllerDelegate {
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
        
        let newButton  = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "processAction:")
        navigationItem.rightBarButtonItem = newButton

        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            self.managedObjectContext = delegate.managedObjectContext
        }
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            logError("An error occurred getting results from fetchedResultsController in RawRaceDataTableViewController")
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
        setTableViewBackgroundGradient(cell, topColor: UIColor(red: 0.133, green: 0.133, blue: 0.133, alpha: 1), bottomColor: UIColor.blackColor())
        if let rundata = fetchedResultsController?.objectAtIndexPath(indexPath) as? RunData {
            cell.latLonLabel.text = formatLatLonPrintA(CLLocationCoordinate2DMake(Double(rundata.lattitude!), Double(rundata.longitude!)) , type: .degreeDecimalMinutes)
            cell.gpsDataLabel.text = String(format:"Speed:%6.2f Kph Distance:%6.2f",Double(rundata.speed!) * 3.6, Double(rundata.distance!))
            cell.pedometerDataLabel.text = String(format:"Steps:%d Pace:%6.2f Altitude:%6.2f",Int(rundata.stepsTaken!), Double(rundata.currentPace!),Double(rundata.altitude!))
            cell.latLonLabel.textColor = UIColor.whiteColor()
            cell.gpsDataLabel.textColor = UIColor.whiteColor()
            cell.pedometerDataLabel.textColor = UIColor.whiteColor()
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
    
    func processAction(sender: AnyObject) {
        if let context = self.managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: "RunData")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: true)]
            fetchRequest.predicate = NSPredicate(format:"runDataToRunDetail = %@", self.runDetail!)
            
            do {
                let xfetchedObjects = try context.executeFetchRequest(fetchRequest)
                if(xfetchedObjects.count == 0) {
                    return
                }
                if let dir : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
                    let path = dir.stringByAppendingPathComponent("myrun.kml")
                    
                    
                    let url = NSURL(fileURLWithPath: path)
                   
                    let fileManager = NSFileManager.defaultManager()
                    
                    // Delete 'hello.swift' file
                    
                    do {
                        try fileManager.removeItemAtPath(path)
                    }
                    catch let error as NSError {
                        logError("File to delete did no exist: \(error)")
                    }
                    
                    do {
                        // Write the new KML file
                        let fileHeader = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n<kml xmlns=\"http://earth.google.com/kml/2.1\" xmlns:trails=\"http://www.google.com/kml/trails/1.0\">\r\n<Document>\r\n<name>track.kml</name>\r\n<Placemark>\r\n<name>RealTimeRunning data</name>\r\n<Style>\r\n<LineStyle>\r\n<color>ff0000ff</color>\r\n<width>1</width>\r\n</LineStyle>\r\n</Style>\r\n<MultiGeometry>\r\n<LineString>\r\n<tessellate>1</tessellate>\r\n<coordinates>\r\n"
                        try fileHeader.appendLineToURL(url)
                        for object in xfetchedObjects {
                            if let runData = object as? RunData {
                                let sentence = String(format:"%f,%f,0.0\r\n", Double(runData.longitude!), Double(runData.lattitude!))
                                try sentence.appendLineToURL(url)
                            }
                        }
                        let fileTrailer = "</coordinates>\r\n</LineString>\r\n</MultiGeometry>\r\n</Placemark>\r\n</Document>\r\n</kml>\r\n";
                        try fileTrailer.appendLineToURL(url)
                        
                        sendEmail(path)

                    }
                    catch {
                         logError("Error creating the KML file: \(error)")
                    }
                }
            } catch let error as NSError {
                logError("Fetch failed when creating kml output: \(error.localizedDescription)")
            }
        }
    }
    
    func sendEmail(filePath:String) {
        if let fData = NSData(contentsOfFile: filePath) {
            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self
                mail.setToRecipients(["hello@scottashmore.net"])
                //mail.setToRecipients(["bob.ashmore@dunluce.com"])
                mail.setMessageBody("<p>Hi Just thought you like to see my latest run</p>", isHTML: true)
                mail.setSubject("My Run in Google Earth format")
                mail.addAttachmentData(fData, mimeType:"text/csv", fileName:"myrun.kml")

                presentViewController(mail, animated: true, completion: nil)
            } else {
                logError("Mail send from race history failed: cannot send mail")
            }
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        if let myError = error {
            logError("Mail send from race history failed: \(myError.localizedDescription)")
        }
        switch(result.rawValue) {
            case MFMailComposeResultCancelled.rawValue:
                logError("Mail send from race history: Cancelled")
            case MFMailComposeResultFailed.rawValue:
                logError("Mail send from race history: Failed")
            case MFMailComposeResultSaved.rawValue:
                logError("Mail send from race history: Saved")
            case MFMailComposeResultSent.rawValue:
                logError("Mail send from race history: Sent")
            default:
                logError("Mail send from race history: Default")
        }
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
