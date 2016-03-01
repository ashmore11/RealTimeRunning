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
    var altitude:Double = 0.0
    var pressure:Double = 0.0
    var heading:Double = 0.0
    var durationString:String = ""
    var duration:Double = 0.0
    var startTime:NSDate?
    var endTime:NSDate?
    var myLocationManager:SharedLocationManager? = nil
    var logTimer: NSTimer?
    var raceName:String = ""
    var managedObjectContext:NSManagedObjectContext?
    var bLocationsReceived = false
    var activityManager:CMMotionActivityManager?
    var pedoMeter:CMPedometer?
    var stepsTaken:Int = 0
    var activity:String = ""
    var runDetailObject:RunDetail?
    var pedDistance = 0.0
    var currentPace = 0.0
    var currentCadence = 0.0
    var floorsAscended = 0.0
    var floorsDescended = 0.0

    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var raceDistanceLabel: UILabel!
    @IBOutlet weak var raceStartTimeLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var paceLabel: UILabel!
    @IBOutlet weak var cadenceLabel: UILabel!
    @IBOutlet weak var joinRaceButton: UIButton!

    func receiveAltimeterNotification(notification:NSNotification) {
        let userInfo:NSDictionary = notification.userInfo!
        let altimeterData:CMAltitudeData? = userInfo.objectForKey("Altimeter") as? CMAltitudeData
        if let data = altimeterData {
            pressure = Double(data.pressure)
            altitude = Double(data.relativeAltitude)
        }
    }

    func receiveLocationNotification(notification:NSNotification) {
        let userInfo:NSDictionary = notification.userInfo!
        let location:CLLocation? = userInfo.objectForKey("Location") as? CLLocation
        let newHeading:CLHeading? = userInfo.objectForKey("Heading") as? CLHeading

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
                self.durationLabel.text = String(format:"Duration: %@",self.durationString)
                self.speedLabel.text = String(format:"Speed: %6.2f Kph",self.speed * 3.6)
                self.raceDistanceLabel.text = String(format:"Distanced Raced:%6.2f Meters",self.distance)
            }

        }
        if let hdr = newHeading {
            self.heading = hdr.magneticHeading
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateJoinRaceButton()
        
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            self.managedObjectContext = delegate.managedObjectContext
        }

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        if let theRace = race, let startTime = theRace.startTime {
            self.raceName = startTime
            self.title = self.raceName
        }
        self.activityManager = CMMotionActivityManager()
        self.pedoMeter = CMPedometer()

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
                
                SocketHandler.socket.emit("raceUpdated", self.race.index, self.race.id)
                
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

    // This sets up the motion manager to return step data
    func setupMotionManage() {
        if(CMPedometer.isStepCountingAvailable()){
            if let ped = self.pedoMeter {
                ped.startPedometerUpdatesFromDate(NSDate()) { (data, error) -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if(error == nil){
                            if let stepData = data {
                                self.stepsTaken = Int(stepData.numberOfSteps)
                                if let dst = stepData.distance {
                                    self.pedDistance = Double(dst)
                                }
                                if let pce = stepData.currentPace {
                                    self.currentPace = Double(pce)
                                }
                                if let cad = stepData.currentCadence {
                                    self.currentCadence = Double(cad)
                                }
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.stepsLabel.text = String(format:"Steps taken: %d",self.stepsTaken)
                                    self.paceLabel.text = String(format:"Pace: %6.2f Sec. / Mtr.",self.currentPace)
                                    self.cadenceLabel.text = String(format:"Cadence: %6.2f Steps / Sec.",self.currentCadence)
                                }

                            }
                        }
                        else if (Int(error!.code) == Int(CMErrorMotionActivityNotAuthorized.rawValue)) {
                            self.didEncounterAuthorizationError()
                        }
                    })
                }
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

    func didEncounterAuthorizationError() {
        let title = NSLocalizedString("Motion Activity Not Authorized", comment: "")

        let message = NSLocalizedString("To enable Motion features, please allow access to Motion & Fitness in Settings under Privacy.", comment: "")

        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(cancelAction)

        let openSettingsAction = UIAlertAction(title: "Open Settings", style: .Default) { _ in
            // Open the Settings app.
            let url = NSURL(string: UIApplicationOpenSettingsURLString)!

            UIApplication.sharedApplication().openURL(url)
        }

        alert.addAction(openSettingsAction)

        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alert, animated: true, completion:nil)
        }
    }

    func writeRaceDetail() ->RunDetail? {
        if let context = self.managedObjectContext {
            if let detailObject = NSEntityDescription.insertNewObjectForEntityForName("RunDetail", inManagedObjectContext: context) as? RunDetail {
                detailObject.name = self.raceName
                detailObject.date = self.startTime
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
                    dataObject.altitude = self.altitude
                    dataObject.stepsTaken = self.stepsTaken
                    dataObject.pedDistance = self.pedDistance
                    dataObject.currentPace = self.currentPace
                    dataObject.currentCadence = self.currentCadence
                    dataObject.floorsAscended = self.floorsAscended
                    dataObject.floorsDescended = self.floorsDescended
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
        setupMotionManage()

        // Hide the back button incase the user accidently hits it
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.startTime = NSDate()
        self.bLocationsReceived = false
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"

        let dateString = dateFormatter.stringFromDate(self.startTime!)
        raceStartTimeLabel.text = String(format:"Your start time:%@",dateString)

        geoEvents = []
        myLocationManager = SharedLocationManager.sharedInstance
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"receiveLocationNotification:", name:"locationNotification", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"receiveAltimeterNotification:", name:"altimeterNotification", object:nil)
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
            self.startStopButton.setTitle("Start", forState: .Normal)
            NSNotificationCenter.defaultCenter().removeObserver(self, name:"locationNotification", object:nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name:"altimeterNotification", object:nil)
            self.myLocationManager?.workInBackground(false)
            self.myLocationManager = nil
            self.endTime = NSDate()
            self.pedoMeter!.stopPedometerUpdates()
            self.navigationItem.setHidesBackButton(false, animated: true)
        }

        alert.addAction(finishRaceAction)

        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alert, animated: true, completion:nil)
        }
    }

}
