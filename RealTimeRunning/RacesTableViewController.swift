//
//  RacesTableViewController.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 18/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

class RacesTableViewController: UITableViewController {
    
    var races = [Race]()
        
    override func viewDidLoad() {
        super.viewDidLoad()

        loadSampleRaces()
    }
    
    func loadSampleRaces() {
        
        let components = NSCalendar.currentCalendar().components([.Day, .Month, .Year, .Hour, .Minute, .Second ], fromDate: NSDate())
        components.minute = 0
        components.second = 0
        let startDate = NSCalendar.currentCalendar().dateFromComponents(components)
        
        for index in 0...10 {
            
            let components = NSCalendar.currentCalendar().components([.Hour], fromDate: NSDate())
            components.setValue(index + 1, forComponent: .Hour);
            let startTime = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: startDate!, options: NSCalendarOptions(rawValue: 0))
            
            let race = Race(startTime: startTime!, competitors: [User](), distance: 1)
            
            races.append(race)
            
        }
        
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return races.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cellIdentifier = "RaceTableViewCell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! RaceTableViewCell
        
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = UIColor(red: 0.878, green: 0.517, blue: 0.258, alpha: 1)
        } else {
            cell.backgroundColor = UIColor(red: 0.592, green: 0.172, blue: 0.070, alpha: 1)
        }
        
        let race = races[indexPath.row]
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        let date = dateFormatter.stringFromDate(race.startTime)
        //let toArray = date.componentsSeparatedByString(", ")
        //let formattedDate = toArray.joinWithSeparator(":")
        
        cell.startTimeLabel.text = date
        cell.competitorsLabel.text = "competitors: \(race.competitors!.count)"
        cell.distanceLabel.text = "\(race.distance)km"

        return cell
        
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "raceRecord" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let race = races[indexPath.row]

                if let controller = segue.destinationViewController as? RaceRecordViewController {
                    controller.race = race
                }
            }
        }
    }
    
}
