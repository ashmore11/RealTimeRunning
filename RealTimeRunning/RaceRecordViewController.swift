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
import AVFoundation

class RaceRecordViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Properties
    
    var user: User!
    var race: Race!
    var competitorsData: [[String: AnyObject]] = []
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
    var userPositions = [String: Double]()
    var activityManager:CMMotionActivityManager?
    var pedoMeter:CMPedometer?
    var stepsTaken:Int = 0
    var activity:String = ""
    var pedDistance = 0.0
    var currentPace = 0.0
    var currentCadence = 0.0
    var floorsAscended = 0.0
    var floorsDescended = 0.0
    var altitude:Double = 0.0
    var pressure:Double = 0.0

    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var raceDistanceLabel: UILabel!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var joinRaceButton: UIButton!
    @IBOutlet weak var raceDataButton: UIButton!
    @IBOutlet weak var viewMapButton: UIButton!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var paceLabel: UILabel!
    @IBOutlet weak var statsViewArea: UIView!
    @IBOutlet weak var competitorsTableView: UITableView!

    func receiveAltimeterNotification(notification:NSNotification) {
        let userInfo:NSDictionary = notification.userInfo!
        let altimeterData:CMAltitudeData? = userInfo.objectForKey("Altimeter") as? CMAltitudeData
        if let data = altimeterData {
            self.pressure = Double(data.pressure)
            self.altitude = Double(data.relativeAltitude)
        }
    }

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
                
                self.durationLabel.text = self.durationString
                self.speedLabel.text = String(format: "%6.2f Kph", self.speed * 3.6)
                self.raceDistanceLabel.text = String(format: "%6.2f Km", self.distance / 1000)
                
                SocketIOManager.sharedInstance.sendPositionUpdate(self.user.id, distance: self.distance, speed: self.speed)
            
            }

        }
        
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.competitorsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.getTableViewData()
        
        competitorsTableView.delegate = self
        competitorsTableView.dataSource = self
        competitorsTableView.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.3)
        
        setViewGradient(self.view)
        setButtonGradient(startStopButton, joinRaceButton, raceDataButton, viewMapButton)
        updateJoinRaceButton()
        statsViewArea.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.6)
        
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            
            self.managedObjectContext = delegate.managedObjectContext
        
        }
        
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
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return competitorsData.count
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellIdentifier = "CompetitorsTableViewCell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! CompetitorsTableViewCell
        
        setTableViewBackgroundGradient(cell, topColor: UIColor(red: 0.100, green: 0.100, blue: 0.100, alpha: 1), bottomColor: UIColor.blackColor())
        
        cell.backgroundColor = UIColor.clearColor()
        
        let competitor = competitorsData[indexPath.row]
        
        if let name = competitor["name"] as? String, let image = competitor["image"] as? UIImage {
            
            cell.nameLabel.text = name
            cell.profileImage.image = image
            
        }
        
        return cell
        
    }
    
    func getTableViewData() {
        
        self.competitorsData = [[String: AnyObject]]()
        
        for id in race.competitors! {
    
            let url = "http://real-time-running.herokuapp.com/api/users/\(id)"

            Alamofire.request(.GET, url).responseSwiftyJSON({ (request, response, json, error) in

                if let name = json[0]["name"].string, let imageURL = json[0]["profileImage"].string, let nsurl = NSURL(string: imageURL), let data = NSData(contentsOfURL:nsurl), let image = UIImage(data:data) {
                    
                    let data = [
                        "name": name,
                        "image": image
                    ]
                    
                    self.competitorsData.append(data)
                    
                    self.competitorsTableView.reloadData()

                }
                
            })
            
        }
        
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
                
                SocketIOManager.sharedInstance.raceUsersUpdated(self.race.index, id: self.race.id)
                
                hideActivityIndicator(self.view)
                
                self.updateCompetitorsArray()
            
        })
        
    }
    
    func updatePositions(notification: NSNotification) {
        
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .OrdinalStyle
        
        if let items = notification.object, let id = items["id"] as? String, let distance = items["distance"] as? Double {
            
            self.userPositions[id] = distance
            
            let sortedPositions = self.userPositions.sort { $0.1 > $1.1 }
            
            let keys = sortedPositions.map { return $0.0 }
            
            for (index, element) in keys.enumerate() {
                
                if element == self.user.id {
                    
                    self.positionLabel.text = formatter.stringFromNumber(index + 1)
                    
                }
                
            }
            
        }
        
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
            
            self.joinRaceButton.setTitle("LEAVE RACE" , forState: .Normal)
            
        } else {
            
            self.joinRaceButton.setTitle("JOIN RACE", forState: .Normal)
            
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
                detailObject.date = NSDate()
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
        logError("Race Started")
        
        let voice = AVSpeechSynthesizer()
        let myUtterance = AVSpeechUtterance(string: "Your race has begun")
        voice.speakUtterance(myUtterance)

        // Hide the back button incase the user accidently hits it
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.bLocationsReceived = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"receiveLocationNotification:", name:"locationNotification", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"receiveAltimeterNotification:", name:"altimeterNotification", object:nil)

        geoEvents = []
        myLocationManager = SharedLocationManager.sharedInstance
        myLocationManager?.workInBackground(true)
        myLocationManager?.resetDistance()
        
        self.runDetailObject = writeRaceDetail()
        
        // Start a timer that will run the updateLog function once every second
        self.logTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateLog", userInfo: nil, repeats: true)
        self.startStopButton.setTitle("STOP", forState: .Normal)
    
    }

    func willStopRace() {
        logError("Race Stoped")
        if let ped = self.pedoMeter {
            ped.stopPedometerUpdates()
        }
        
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
            NSNotificationCenter.defaultCenter().removeObserver(self, name:"altimeterNotification", object:nil)
            
            self.startStopButton.setTitle("START", forState: .Normal)
            self.myLocationManager?.workInBackground(false)
            self.myLocationManager = nil
            
            self.navigationItem.setHidesBackButton(false, animated: true)
            
        }

        alert.addAction(finishRaceAction)

        dispatch_async(dispatch_get_main_queue()) {
            
            self.presentViewController(alert, animated: true, completion:nil)
            
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
                                    //self.stepsLabel.text = String(format:"Steps taken: %d",self.stepsTaken)
                                    self.paceLabel.text = String(format:"%6.2f Sec/Mtr", self.currentPace)
                                    //self.cadenceLabel.text = String(format:"Cadence: %6.2f Steps / Sec.",self.currentCadence)
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
