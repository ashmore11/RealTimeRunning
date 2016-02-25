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

class RacesTableViewController: UITableViewController {
    
    var races = [Race]()
    var user: User?
        
    override func viewDidLoad() {
        super.viewDidLoad()

        loadRaces()
    }
    
    func loadRaces() {
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        Alamofire.request(.GET, "http://192.168.168.108:3000/api/races").responseSwiftyJSON({ (request, response, json, error) in
            
            for (_, value) in json {
                
                if let raceId = value["_id"].string, let startTime = value["startTime"].string, let parsedDate = formatter.dateFromString(startTime), let competitors = value["competitors"].array, let distance = value["distance"].int {
                    
                    let race = Race(id: raceId, startTime: parsedDate, competitors: competitors, distance: distance)
                    
                    self.races.append(race)
                    
                }
                
            }
            
            self.tableView.reloadData()
            
        })
        
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
        
        cell.startTimeLabel.text = date
        cell.competitorsLabel.text = "competitors: \(race.competitors!.count)"
        cell.distanceLabel.text = "\(race.distance)km"

        return cell
        
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "raceRecord" {
            
            if let indexPath = self.tableView.indexPathForSelectedRow {
                
                let race = races[indexPath.row]

                if let controller = segue.destinationViewController as? RaceRecordViewController {
                    
                    controller.race = race
                    controller.user = user
                    
                }
                
            }
            
        }
        
    }
    
}
