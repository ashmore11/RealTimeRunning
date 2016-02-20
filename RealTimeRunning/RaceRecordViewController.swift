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
    var race:Race?

    var geoEvents:[CLLocationCoordinate2D] = []
    var lat:Double = 0.0
    var lon:Double = 0.0
    var speed:Double = 0.0
    var heading:Double = 0.0
    var distance:Double = 0.0
    var durationString:String = ""
    var duration:Double = 0.0
    var startTime:NSDate?
    var endTime:NSDate?
    var myLocationManager:SharedLocationManager? = nil

    @IBOutlet weak var startStopButton: UIButton!
    
    @IBOutlet weak var raceDistanceLabel: UILabel!
    @IBOutlet weak var raceStartTimeLabel: UILabel!
    
    @IBOutlet weak var raceAverageSpeedLabel: UILabel!
    
    @IBAction func startStopPressed(sender: AnyObject) {
        if myLocationManager == nil {
            self.startTime = NSDate()
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss"
            
            let dateString = dateFormatter.stringFromDate(self.startTime!)
            raceStartTimeLabel.text = String(format:"Your start time:%@",dateString)
            
            geoEvents = []
            myLocationManager = SharedLocationManager.sharedInstance
            NSNotificationCenter.defaultCenter().addObserver(self, selector:"receiveLocationNotification:", name:"locationNotification", object:nil)
            myLocationManager?.workInBackground(true)
            myLocationManager?.resetDistance()
            self.startStopButton.setTitle("Stop", forState: .Normal)
        }
        else {
            self.startStopButton.setTitle("Start", forState: .Normal)
            NSNotificationCenter.defaultCenter().removeObserver(self, name:"locationNotification", object:nil)
            myLocationManager?.workInBackground(false)
            myLocationManager = nil
            self.endTime = NSDate()
        }
    }
    
    func receiveLocationNotification(notification:NSNotification) {
        let userInfo:NSDictionary = notification.userInfo!
        let location:CLLocation? = userInfo.objectForKey("Location") as? CLLocation
        let newHeading:CLHeading? = userInfo.objectForKey("Heading") as? CLHeading
        
        if let loc = location  {
            self.lat = loc.coordinate.latitude
            self.lon = loc.coordinate.longitude
            self.speed = loc.speed
            self.distance = (myLocationManager?.getDistance())!
            self.durationString = (myLocationManager?.getDuration())!
            self.duration = (myLocationManager?.getDurationDouble())!
            let x = CLLocationCoordinate2DMake(lat, lon)
            geoEvents.append(x)
            if self.duration > 0.0000001 {
                let distancek = distance / 1000.0
                let avgSpeed = distancek / self.duration
                self.raceAverageSpeedLabel.text =  String(format:"Average Speed:%6.2f Kph",avgSpeed)
            }
            self.raceDistanceLabel.text = String(format:"Distanced Raced:%6.2f Meters",self.distance)
            print("lat: \(self.lat) lon: \(self.lon) distance: \(self.distance) duration: \(self.duration)")
        }
        if let hdr = newHeading {
            self.heading = hdr.magneticHeading;
            print("Heading: \(self.heading)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        if let theRace = race {
            let date = dateFormatter.stringFromDate(theRace.startTime)
            self.title = String(format:"Race:%@",date)
        }


        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showMap" {
            if let controller = segue.destinationViewController as? MapViewController {
                controller.geoEvents = geoEvents
            }
        }
    }

}
