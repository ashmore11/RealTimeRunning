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
import Alamofire

class RaceRecordViewController: UIViewController {
    var race:Race?
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

    var activityManager:CMMotionActivityManager?
    var pedoMeter:CMPedometer?
    var stepsTaken:Int = 0
    var activity:String = ""

    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var startStopButton: UIButton!
    
    @IBOutlet weak var raceDistanceLabel: UILabel!
    @IBOutlet weak var raceStartTimeLabel: UILabel!
    
    @IBOutlet weak var raceAverageSpeedLabel: UILabel!
    
    @IBAction func startStopPressed(sender: AnyObject) {
        if myLocationManager == nil {
            //setupMotionManage()

            // Start a timer that will run the updateLog function once every second
            self.logTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateLog", userInfo: nil, repeats: true)

            self.startTime = NSDate()
            
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
            self.startStopButton.setTitle("Stop", forState: .Normal)
        }
        else {
            if self.logTimer != nil {
                self.logTimer!.invalidate()
                self.logTimer = nil
            }
            self.startStopButton.setTitle("Start", forState: .Normal)
            NSNotificationCenter.defaultCenter().removeObserver(self, name:"locationNotification", object:nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name:"altimeterNotification", object:nil)
            myLocationManager?.workInBackground(false)
            myLocationManager = nil
            self.endTime = NSDate()
        }
    }
    
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
            self.lat = loc.coordinate.latitude
            self.lon = loc.coordinate.longitude
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
                self.raceAverageSpeedLabel.text =  String(format:"Average Speed:%6.2f Kph",avgSpeed)
            }
            self.durationLabel.text = String(format:"Duration:%@",self.durationString)
            self.speedLabel.text = String(format:"Speed:%6.2f Kph",self.speed * 3.6)
            self.raceDistanceLabel.text = String(format:"Distanced Raced:%6.2f Meters",self.distance)
        }
        if let hdr = newHeading {
            self.heading = hdr.magneticHeading
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        Alamofire.request(.GET, "https://httpbin.org/get", parameters: ["foo": "bar"])
            .responseJSON { response in
                print("TESTING alamofire")
                print("request")
                print(response.request)  // original URL request
                print("response")
                print(response.response) // URL response
                print("data")
                print(response.data)     // server data
                print("result")
                print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                }
        }
        
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        if let theRace = race {
            let date = dateFormatter.stringFromDate(theRace.startTime)
            self.title = String(format:"Race:%@",date)
        }
        //self.activityManager = CMMotionActivityManager()
        //self.pedoMeter = CMPedometer()

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
    
    // This doesnt work in this app but it works if i add it to a new app ????
    func setupMotionManage() {
        
        /*
        
        let cal = NSCalendar.currentCalendar()
        let comps = NSCalendar.currentCalendar().components([.Day, .Month, .Year, .Hour, .Minute, .Second ], fromDate: NSDate())
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        let timeZone = NSTimeZone.systemTimeZone()
        cal.timeZone = timeZone
        
        let midnightOfToday = cal.dateFromComponents(comps)!
        
        if(CMMotionActivityManager.isActivityAvailable()){
            print("Motion Activity available")
            self.activityManager!.startActivityUpdatesToQueue(NSOperationQueue.mainQueue()) { data in
                if let rawdata = data {
                    dispatch_async(dispatch_get_main_queue()) {
                        if(rawdata.stationary == true){
                            self.activity = "Stationary"
                        } else if (rawdata.walking == true){
                            self.activity = "Walking"
                        } else if (rawdata.running == true){
                            self.activity = "Running"
                        } else if (rawdata.automotive == true){
                            self.activity = "Automotive"
                        }
                    }
                }
                else {
                    print("ERROR Motion Activity data is nil")
                   
                }
            }
        }
        if(CMPedometer.isStepCountingAvailable()){
            let fromDate = NSDate(timeIntervalSinceNow: -86400 * 7)
            self.pedoMeter!.queryPedometerDataFromDate(fromDate, toDate: NSDate()) { (data , error) -> Void in
                print(data)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if(error == nil){
                        self.stepsTaken = Int(data!.numberOfSteps)
                    }
                    else if (Int(error!.code) == Int(CMErrorMotionActivityNotAuthorized.rawValue)) {
                        self.didEncounterAuthorizationError()
                        //print( "******************* Not Authorised to use Motion Data *******************")
                    }
                    
                })
                
            }
        */
        
        if(CMPedometer.isStepCountingAvailable()){
            self.pedoMeter!.startPedometerUpdatesFromDate(NSDate()) { (data, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if(error == nil){
                        self.stepsTaken = Int(data!.numberOfSteps)
                    }
                    else if (Int(error!.code) == Int(CMErrorMotionActivityNotAuthorized.rawValue)) {
                        self.didEncounterAuthorizationError()
                        //print( "******************* Not Authorised to use Motion Data *******************")
                    }
                })
            }
        }
    
    }
    
    // This function will be used for logging data
    func updateLog() {
        
        print("Logging lat: \(self.lat) lon: \(self.lon) distance: \(self.distance) duration: \(self.duration) speed: \(self.speed)")
        print("Logging Relative Altitude: \(altitude) Pressure: \(pressure)")
        print("Logging Heading: \(self.heading)")

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


}
