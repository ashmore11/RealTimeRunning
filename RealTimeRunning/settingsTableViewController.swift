//
//  settingsTableViewController.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 25/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import CoreData

class settingsTableViewController: UITableViewController {

    @IBOutlet weak var metricOrImperialSegmentCtl: UISegmentedControl!

    @IBOutlet weak var logFrequencySlider: UISlider!
    @IBOutlet weak var logFrequencyLabel: UILabel!
    
    var logFrequency = 20
    var displayUnits:String = ""
    
    var managedObjectContext:NSManagedObjectContext?
    
    @IBAction func didChangeMeasure(sender: AnyObject) {
    
        switch metricOrImperialSegmentCtl.selectedSegmentIndex
        {
            case 0:
                print("Segment Changed Metric selected")
                self.displayUnits = "metric"
            case 1:
                print("Segment Changed Imperial selected")
                self.displayUnits = "imperial"
            default:
                break
        }
        saveDb()
    }
    
    @IBAction func logFrequencyChanged(sender: UISlider) {
        self.logFrequency = Int(sender.value)
        self.logFrequencyLabel.text = "\(self.logFrequency)"
        saveDb()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        self.tableView.backgroundColor = UIColor.blackColor()
        if let settings = readSettingsFromDb() {
            if let units = settings.displayUnits {
                self.displayUnits = units
            }
            if let logfq = settings.loggingFrequency {
                self.logFrequency = Int(logfq)
            }
            
            if self.displayUnits == "metric" {
                self.metricOrImperialSegmentCtl.selectedSegmentIndex = 0
            }
            else {
                self.metricOrImperialSegmentCtl.selectedSegmentIndex = 1
            }
            self.logFrequencyLabel.text = "\(self.logFrequency)"


        }
        self.logFrequencySlider.setValue(Float(logFrequency), animated:true)
        self.logFrequencyLabel.text = "\(logFrequency)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Make the seperator lines between cells go all the way to the view's left edge
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layoutMargins = UIEdgeInsetsZero
        cell.separatorInset = UIEdgeInsetsZero
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.layoutMargins = UIEdgeInsetsZero
    }
    
    
    func saveDb() {
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            self.managedObjectContext = delegate.managedObjectContext
            if let context = self.managedObjectContext {
                
                do {
                    let fetchRequest = NSFetchRequest(entityName: "Settings")
                    fetchRequest.fetchLimit = 1
                    let result = try context.executeFetchRequest(fetchRequest)
                    if result.count > 0 {
                        let rundata = result[0]
                        if let object = rundata as? Settings {
                            object.displayUnits = self.displayUnits
                            object.loggingFrequency = self.logFrequency
                        }
                    }
                    else {
                        if let newObject = NSEntityDescription.insertNewObjectForEntityForName("Settings", inManagedObjectContext: context) as? Settings {
                            newObject.displayUnits = self.displayUnits
                            newObject.loggingFrequency = self.logFrequency
                        }
                    }
                    try context.save()

                } catch {
                    let fetchError = error as NSError
                    logError("Error while saving settings data: \(fetchError.description)")
                }
            }
        }
    }


}
