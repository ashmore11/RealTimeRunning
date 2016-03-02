//
//  RaceRecordViewController.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 20/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion
import CoreData
import Alamofire
import SwiftyJSON
import Alamofire_SwiftyJSON
import MBProgressHUD

class RaceRecordViewController: UIViewController {
    
    // MARK: Properties
    
    var user: User!
    var race: Race!
    var geoEvents:[CLLocationCoordinate2D] = []
    var lat:Double = 0.0
    var lon:Double = 0.0
    var speed:Double = 0.0
    var distance:Double = 0.0
    var durationString:String = ""
    var duration:Double = 0.0
    var myLocationManager:SharedLocationManager? = nil
    var logTimer: NSTimer?
    var raceName:String = ""
    var managedObjectContext:NSManagedObjectContext?
    var bLocationsReceived = false
    var runDetailObject:RunDetail?

    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var raceDistanceLabel: UILabel!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var joinRaceButton: UIButton!
    @IBOutlet weak var raceDataButton: UIButton!
    @IBOutlet weak var viewMapButton: UIButton!

    func receiveLocationNotification(notification: NSNotification) {
        
        let userInfo:NSDictionary = notification.userInfo!
        let location:CLLocation? = userInfo.objectForKey("Location") as? CLLocation

        if let loc = location  {
            
            self.bLocationsReceived = true

            self.lat = loc.coordinate.latitude
            self.lon = loc.coordinate.longitude
        
            if let lMgr = myLocationManager {
             
                self.speed = lMgr.getStableSpeed()
                self.distance = lMgr.getDistance()
                self.durationString = lMgr.getDuration()
                self.duration = lMgr.getDurationDouble()
            
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                
                self.durationLabel.text = String(format:"Duration: %@", self.durationString)
                self.speedLabel.text = String(format:"Speed: %6.2f Kph", self.speed * 3.6)
                self.raceDistanceLabel.text = String(format:"Distanced Raced: %6.2f Meters", self.distance)
            
            }

        }
        
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setViewGradient(self.view)
        setButtonGradient(startStopButton, joinRaceButton, raceDataButton, viewMapButton)
        updateJoinRaceButton()
        
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            
            self.managedObjectContext = delegate.managedObjectContext
        
        }
        
        if let theRace = race, let startTime = theRace.startTime {
            
            self.raceName = startTime
            self.title = self.raceName
            
        }

        // disable the interactivePopGestureRecognizer so you cant slide from left to pop the current view
        if self.navigationController!.respondsToSelector("interactivePopGestureRecognizer") {
            
            self.navigationController!.interactivePopGestureRecognizer!.enabled = false
            
        }
        
    }

    override func viewDidAppear(animated:Bool) {
        
        super.viewDidAppear(animated)
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        
    }

    override func viewDidDisappear(animated:Bool) {
        
        super.viewDidDisappear(animated)
        
        UIApplication.sharedApplication().idleTimerDisabled = false
        
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
        
    }
    
    // MARK: Actions
    
    @IBAction func startStopPressed(sender: AnyObject) {
        
        if myLocationManager == nil {
        
            self.willStartRace()
        
        } else {
        
            self.willStopRace()
        
        }
        
    }
    
    @IBAction func joinButtonPressed(sender: UIButton) {
        
        showActivityIndicator(self.view, text: nil)
        
        let requestURL = "http://real-time-running.herokuapp.com/api/races/\(race.id)"
        let parameters = ["id": user.id]
        
        Alamofire.request(.PUT, requestURL, parameters: parameters, encoding: .JSON)
            .responseSwiftyJSON({ (request, response, json, error) in
            
                if (error != nil) {
                    print(error)
                    return
                }
                
                SocketIOManager.sharedInstance.raceUsersUpdated(self.race.index, id: self.race.id) { _ in
                 
                    print("emit complete")
                    
                }
                
                hideActivityIndicator(self.view)
                
                self.updateCompetitorsArray()
            
        })
        
    }
    
    func updateCompetitorsArray() {
        
        if let index = race.competitors?.indexOf(user.id) {
            
            race.competitors?.removeAtIndex(index)
            
        } else {
            
            race.competitors?.append(user.id)
            
        }
        
        updateJoinRaceButton()
        
    }
    
    func updateJoinRaceButton() {
        
        if race.competitors!.contains(user.id) {
            
            self.joinRaceButton.setTitle("Leave Race", forState: .Normal)
            
        } else {
            
            self.joinRaceButton.setTitle("Join Race", forState: .Normal)
            
        }
        
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showMap" {

            if let controller = segue.destinationViewController as? MapViewController {

                controller.geoEvents = geoEvents

            }

        } else if segue.identifier == "showRaw" {

            if let controller = segue.destinationViewController as? RawRaceDataTableViewController {

                controller.runDetail = self.runDetailObject

            }

        }

    }
    
    // This function will be used for logging data
    func updateLog() {
        
        self.writeRaceData()
        let x = CLLocationCoordinate2DMake(self.lat, self.lon)
        geoEvents.append(x)
        
        //print("Logging lat: \(self.lat) lon: \(self.lon) distance: \(self.distance) duration: \(self.duration) speed: \(self.speed)")
        //print("Logging Relative Altitude: \(altitude) Pressure: \(pressure)")
        //print("Logging Heading: \(self.heading)")
        
    }

    func writeRaceDetail() -> RunDetail? {
        
        if let context = self.managedObjectContext {
            
            if let detailObject = NSEntityDescription.insertNewObjectForEntityForName("RunDetail", inManagedObjectContext: context) as? RunDetail {
                
                detailObject.name = self.raceName
                detailObject.distance = 10.0
                detailObject.organiser = "East London athletics club"
                detailObject.contact = "Scott 123 45678"
                
                self.saveData()
                
                return detailObject
                
            }
            
        }
        
        return nil
        
    }

    func writeRaceData() {
        
        if self.bLocationsReceived == false {
            
            return
            
        }

        if let context = self.managedObjectContext {
            
            if let runDetail = self.runDetailObject {
                
                if let dataObject = NSEntityDescription.insertNewObjectForEntityForName("RunData", inManagedObjectContext: context) as? RunData {
                    
                    dataObject.timeStamp = NSDate()
                    dataObject.lattitude = self.lat
                    dataObject.longitude = self.lon
                    dataObject.speed = self.speed
                    dataObject.distance = self.distance
                    dataObject.runDataToRunDetail = runDetail
                    
                    self.saveData()
                    
                }
                
            }
            
        }
        
    }

    func saveData() {
        
        do {
            
            try self.managedObjectContext!.save()
            
        } catch {
            
            fatalError("Failure to save context: \(error)")
            
        }
        
    }

    func willStartRace() {

        // Hide the back button incase the user accidently hits it
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.bLocationsReceived = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"receiveLocationNotification:", name:"locationNotification", object:nil)

        geoEvents = []
        myLocationManager = SharedLocationManager.sharedInstance
        myLocationManager?.workInBackground(true)
        myLocationManager?.resetDistance()
        
        self.runDetailObject = writeRaceDetail()
        
        // Start a timer that will run the updateLog function once every second
        self.logTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateLog", userInfo: nil, repeats: true)
        self.startStopButton.setTitle("Stop", forState: .Normal)
    
    }

    func willStopRace() {
        
        let title = NSLocalizedString("Finished Race", comment: "")

        let message = NSLocalizedString("By pressing OK you will finish the current race and logging will stop.", comment: "")

        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(cancelAction)

        let finishRaceAction = UIAlertAction(title: "Finish Race", style: .Default) { _ in
            
            self.bLocationsReceived = false
            
            if self.logTimer != nil {
                
                self.logTimer!.invalidate()
                self.logTimer = nil
                
            }
            
            NSNotificationCenter.defaultCenter().removeObserver(self, name:"locationNotification", object:nil)
            
            self.startStopButton.setTitle("Start", forState: .Normal)
            self.myLocationManager?.workInBackground(false)
            self.myLocationManager = nil
            
            self.navigationItem.setHidesBackButton(false, animated: true)
            
        }

        alert.addAction(finishRaceAction)

        dispatch_async(dispatch_get_main_queue()) {
            
            self.presentViewController(alert, animated: true, completion:nil)
            
        }
        
    }

}
