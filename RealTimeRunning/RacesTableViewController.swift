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

class RacesTableViewController: UITableViewController {
    
    // MARK: Properties

    var userId: String?
    var races = [Race]()

    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tableView.backgroundColor = UIColor.blackColor()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadTableViewCell:", name: "competitorsUpdated", object: nil)
        
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
        
        setTableViewBackgroundGradient(cell, topColor: UIColor(red: 0.100, green: 0.100, blue: 0.100, alpha: 1), bottomColor: UIColor.blackColor())
        
        cell.backgroundColor = UIColor.clearColor()
        
        let race = races[indexPath.row]
        
        cell.startTimeLabel.text = "\(race.getStartTime(indexPath.row))"
        cell.competitorsLabel.text = "competitors: \(race.competitors?.count ?? 0)".uppercaseString
        cell.distanceLabel.text = "\(race.distance) km"

        return cell
        
    }
    
    func reloadTableViewCell(notification: NSNotification) {
        
        if let items = notification.object, let id = items["raceId"] as? String {
        
            let requestURL = "http://real-time-running.herokuapp.com/api/races/\(id)"

            Alamofire.request(.GET, requestURL).responseSwiftyJSON({ (request, response, json, error) in
                
                if error != nil {
                    print(error)
                    return
                }
                        
                if let index = self.races.indexOf({ $0.id == id }), let competitors = json[0]["competitors"].arrayObject as? [String] {
                    
                    self.races[index].competitors = competitors
                    
                    dispatch_async(dispatch_get_main_queue()) {
                    
                        let indexPath = NSIndexPath(forRow: index, inSection: 0)
                        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Middle)
                        
                    }
                }
            })
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "raceRecord" {
            
            if let indexPath = self.tableView.indexPathForSelectedRow {
                
                let race = races[indexPath.row]
                
                if let controller = segue.destinationViewController as? RaceRecordViewController, let userId = self.userId {
                    
                    controller.race = race
                    controller.userId = userId
                    
                }
            }
        }
    }
    
}
