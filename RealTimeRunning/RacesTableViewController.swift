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

class RacesTableViewController: UITableViewController {
    
    // MARK: Properties
    
    var races = [Race]()
    var user: User!
        
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tableView.backgroundColor = UIColor(red: 0.878, green: 0.517, blue: 0.258, alpha: 1)
        
        bindEvents()
        
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

        let color1 = UIColor(red: 0.133, green: 0.133, blue: 0.133, alpha: 1)
        let color2 = UIColor(red: 0.078, green: 0.039, blue: 0.015, alpha: 1)
        
        setTableViewBackgroundGradient(cell, topColor: color1, bottomColor: color2)
        
        cell.backgroundColor = UIColor.clearColor()
        
        let race = races[indexPath.row]
        
        race.startTime = getStartTime(indexPath.row)
        
        cell.startTimeLabel.text = race.startTime
        cell.competitorsLabel.text = "competitors: \(race.competitors!.count)"
        cell.distanceLabel.text = "\(race.distance)km"

        return cell
        
    }
    
    func setTableViewBackgroundGradient(sender: UITableViewCell, topColor: UIColor, bottomColor: UIColor) {
        
        let gradientBackgroundColors = [topColor.CGColor, bottomColor.CGColor]
        let gradientLocations = [0.0, 1.0]
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientBackgroundColors
        gradientLayer.locations = gradientLocations
        
        gradientLayer.frame = sender.bounds
        let backgroundView = UIView(frame: sender.bounds)
        backgroundView.layer.insertSublayer(gradientLayer, atIndex: 0)
        sender.backgroundView = backgroundView
    
    }
    
    func bindEvents() {
        
        SocketHandler.socket.on("reloadRaceView") {data, ack in
            
            self.getTableViewData()
            
        }
        
    }
    
    func getTableViewData() {
        
        races = [Race]()

        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Indeterminate
        loadingNotification.labelText = "Loading"

        Alamofire.request(.GET, "http://real-time-running.herokuapp.com/api/races").responseSwiftyJSON({ (request, response, json, error) in
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in

                if let err = error{
                    
                    print("Error:\(err)")
                
                    return
                
                }
                
                for (_, value) in json {
                    
                    if let raceId = value["_id"].string, let createdAt = value["createdAt"].string, let parsedDate = formatter.dateFromString(createdAt), let competitors = value["competitors"].array, let distance = value["distance"].int, let live = value["live"].bool {
                        
                        let race = Race(id: raceId, createdAt: parsedDate, competitors: competitors, distance: distance, live: live)
                        
                        self.races.append(race)
                        
                    }
                    
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    
                    self.tableView.reloadData()
                    
                    MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                    
                }
                
            })

        })
        
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
