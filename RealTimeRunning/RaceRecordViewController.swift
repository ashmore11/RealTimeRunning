//
//  RaceRecordViewController.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 20/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import CoreLocation

class RaceRecordViewController: UIViewController {
    
    // MARK: Properties
    
    var race: Race?
    var geoEvents: [CLLocationCoordinate2D] = []
    var lat: Double = 0.0
    var lon: Double = 0.0
    var speed: Double = 0.0
    var accuracy: Double = 0.0
    var distance: Double = 0.0
    var durationString: String = ""
    var duration: Double = 0.0
    var myLocationManager: SharedLocationManager? = nil

    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var averageSpeedLabel: UILabel!
    @IBOutlet weak var competitorsButton: UIButton!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        if let theRace = race {
            
            let date = dateFormatter.stringFromDate(theRace.startTime)
            self.title = "\(date)"
            
            if theRace.competitors?.count == 0 {
                
                competitorsButton.enabled = false
                
                competitorsButton.alpha = 0.2
                
            }
            
        }

    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
        
    }
    
    // MARK: Actions
    
    @IBAction func startStopPressed(sender: UIButton) {
        
        if myLocationManager == nil {
            
            geoEvents = []
            myLocationManager = SharedLocationManager.sharedInstance
            
            self.startStopButton.setTitle("Stop", forState: .Normal)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "receiveLocationNotification:", name: "locationNotification", object: nil)
            myLocationManager?.workInBackground(true)
            myLocationManager?.resetDistance()
            
        } else {
            
            self.startStopButton.setTitle("Start", forState: .Normal)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: "locationNotification", object: nil)
            myLocationManager?.workInBackground(false)
            myLocationManager = nil
            
        }
        
    }
    
    func receiveLocationNotification(notification: NSNotification) {
        
        let userInfo:NSDictionary = notification.userInfo!
        let location:CLLocation? = userInfo.objectForKey("Location") as? CLLocation
        
        if let loc = location {
            
            self.lat = loc.coordinate.latitude
            self.lon = loc.coordinate.longitude
            self.accuracy = loc.horizontalAccuracy
            
            if let lMgr = myLocationManager {
                
                self.speed = lMgr.getStableSpeed()
                self.distance = lMgr.getDistance()
                self.durationString = lMgr.getDuration()
                self.duration = lMgr.getDurationDouble()
                
            }
            
            let x = CLLocationCoordinate2DMake(lat, lon)
            geoEvents.append(x)
            
            if self.duration > 0.0000001 {
                
                let distancek = distance / 1000.0
                let avgSpeed = distancek / self.duration
                self.averageSpeedLabel.text =  "Average Speed: \(avgSpeed) Kph"
            
            }
            
            self.durationLabel.text = "Duration: \(self.durationString)"
            self.speedLabel.text = "Speed: \(self.speed * 3.6) Kph"
            self.distanceLabel.text = "Distanced Raced: \(self.distance) Meters"
            self.accuracyLabel.text = "Accuracy: \(self.accuracy) Meters"
            
            // print("lat: \(self.lat) lon: \(self.lon) distance: \(self.distance) duration: \(self.duration)")
            
        }
    }
    
    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showMap" {
            
            if let controller = segue.destinationViewController as? MapViewController {
                
                controller.geoEvents = geoEvents
                
            }
            
        } else if segue.identifier == "raceCompetitors" {
            
            let backItem = UIBarButtonItem()
            backItem.title = "RACE"
            navigationItem.backBarButtonItem = backItem
            
            if let controller = segue.destinationViewController as? RaceCompetitorsTableViewController, let competitors = race?.competitors {
                    
                controller.competitors = competitors
                
            }
            
        }
        
    }

}
