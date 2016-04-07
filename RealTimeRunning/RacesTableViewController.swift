//
//  RacesTableViewController.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 18/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

class RacesTableViewController: UITableViewController {
    
    // MARK: Properties
    let races: Races = Races.sharedInstance
    var competitors: Competitors?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tableView.backgroundColor = UIColor.blackColor()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RacesTableViewController.reloadTableView), name: "reloadRaces", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RacesTableViewController.reloadTableViewCell), name: "raceUpdated", object: nil)
        
    }

    // MARK: Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    
        return 1
    
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        return self.races.count
    
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cellIdentifier = "RaceTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! RaceTableViewCell
        
        setTableViewBackgroundGradient(cell, topColor: UIColor(red: 0.100, green: 0.100, blue: 0.100, alpha: 1), bottomColor: UIColor.blackColor())
        cell.backgroundColor = UIColor.clearColor()
        
        let race = self.races.sorted[indexPath.row]
        
        cell.startTimeLabel.text = "\(race.getStartTime(indexPath.row))"
        cell.competitorsLabel.text = "competitors: \(race.competitors?.count ?? 0)".uppercaseString
        cell.distanceLabel.text = "\(race.distance ?? 0) km"

        return cell
        
    }
    
    func reloadTableView(notification: NSNotification) {
        
        self.tableView.reloadData()
        
    }
    
    func reloadTableViewCell(notification: NSNotification) {
        
        if let id = notification.object as? String {
            if let index = self.races.index(id) {
                let indexPath = NSIndexPath(forRow: index, inSection: 0)
                self.tableView.beginUpdates()
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                self.tableView.endUpdates()
            }
        }
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let race = self.races.sorted[indexPath.row]
        
        if let id = race.id {
            self.competitors = Competitors(raceId: id)
            self.competitors?.events.listenTo("competitorsReady", action: {
                self.performSegueWithIdentifier("raceRecord", sender: nil)
            })
        }
    
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "raceRecord" {
                
            if let indexPath = self.tableView.indexPathForSelectedRow {
                
                let race = races.sorted[indexPath.row]
                let startTime = race.getStartTime(indexPath.row)
                
                if let controller = segue.destinationViewController as? RaceRecordViewController {
                    controller.race = race
                    controller.startTime = startTime
                    controller.competitors = self.competitors
                }
            }
        }
    }
    
}
