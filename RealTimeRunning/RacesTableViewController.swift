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

    var user: User!
    var races = [Race]()
    
    let socket:SocketIOClient = SocketIOClient(socketURL: NSURL(string: "http://real-time-running.herokuapp.com")!)

    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        socket.on("connect") {data, ack in
            print("Race socket connected")
        }
        
        socket.on("reloadRaceView") {data, ack in
            print("Race Updates")
            
            self.reloadTableViewCell(data[0] as! Int, id: data[1] as! String)
            
        }

        socket.connect()
        self.tableView.backgroundColor = UIColor.blackColor()
        
        //bindEvents()
        
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
        
        setTableViewBackgroundGradient(cell, topColor: UIColor(red: 0.133, green: 0.133, blue: 0.133, alpha: 1), bottomColor: UIColor.blackColor())
        
        cell.backgroundColor = UIColor.clearColor()
        
        let race = races[indexPath.row]
        
        race.startTime = getStartTime(indexPath.row)
        
        cell.startTimeLabel.text = race.startTime
        cell.competitorsLabel.text = "competitors: \(race.competitors!.count)"
        cell.distanceLabel.text = "\(race.distance)km"

        return cell
        
    }
    
    func bindEvents() {
        
        SocketHandler.socket.on("reloadRaceView") {data, ack in
            
            self.reloadTableViewCell(data[0] as! Int, id: data[1] as! String)
            
        }
        
    }
    
    func reloadTableViewCell(index: Int, id: String) {
        
        let requestURL = "http://real-time-running.herokuapp.com/api/races/\(id)"

        Alamofire.request(.GET, requestURL).responseSwiftyJSON({ (request, response, json, error) in
                    
            if let competitors = json[0]["competitors"].arrayObject as? [String] {
                
                self.races[index].competitors = competitors

            }
            
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Middle)

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
