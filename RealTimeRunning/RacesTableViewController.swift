//
//  RacesTableViewController.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 18/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Alamofire_SwiftyJSON
import MBProgressHUD
import SocketIOClientSwift
import SwiftDDP

class RacesTableViewController: UITableViewController {
    
    // MARK: Properties
    
    let races: MeteorCollection<Race> = (UIApplication.sharedApplication().delegate as! AppDelegate).races
    var userId: String?

    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tableView.backgroundColor = UIColor.blackColor()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadTableViewCell:", name: METEOR_COLLECTION_SET_DID_CHANGE, object: nil)
        
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    
        return 1
    
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        return self.races.sorted.count
    
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cellIdentifier = "RaceTableViewCell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! RaceTableViewCell
        
        setTableViewBackgroundGradient(cell, topColor: UIColor(red: 0.100, green: 0.100, blue: 0.100, alpha: 1), bottomColor: UIColor.blackColor())
        
        cell.backgroundColor = UIColor.clearColor()
        
        let race = self.races.sorted[indexPath.row]
        
        cell.startTimeLabel.text = "\(race.getStartTime(indexPath.row))"
        cell.competitorsLabel.text = "competitors: \(race.competitors?.count ?? 0)".uppercaseString
        cell.distanceLabel.text = "\(race.distance) km"

        return cell
        
    }
    
    func reloadTableViewCell() {
        
        self.tableView.reloadData()
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "raceRecord" {
                
            if let indexPath = self.tableView.indexPathForSelectedRow {
                
                let race = races.sorted[indexPath.row]
                
                if let controller = segue.destinationViewController as? RaceRecordViewController, let userId = self.userId {
                    
                    controller.race = race
                    controller.userId = userId
                    
                }
            }
        }
    }
    
}
