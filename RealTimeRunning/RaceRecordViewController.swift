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
import AVFoundation

class RaceRecordViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Properties
    
    var currentUserId = CurrentUser.sharedInstance.id
    let users: Users = (UIApplication.sharedApplication().delegate as! AppDelegate).users
    let races: Races = (UIApplication.sharedApplication().delegate as! AppDelegate).races
    var race: Race?
    var competitors: Competitors?
    var startTime: String?
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

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if let race = self.race, let startTime = self.startTime, let live = race.live {
            if live == true {
                self.navigationItem.title = "RACE LIVE"
            } else {
                self.navigationItem.title = "RACE BEGINS AT \(startTime)"
            }
        }
        
        self.competitorsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.competitorsTableView.delegate = self
        self.competitorsTableView.dataSource = self
        self.competitorsTableView.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.3)
        
        setViewGradient(self.view)
        setButtonGradient(startStopButton, joinRaceButton, raceDataButton, viewMapButton)
        
        self.statsViewArea.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.6)
        self.updateJoinRaceButton(0)
        
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            self.managedObjectContext = delegate.managedObjectContext
        }
        
        /** 
         * Listen for updates from the database
         */
        self.competitors?.events.listenTo("competitorAdded", action: self.competitorAdded)
        self.competitors?.events.listenTo("competitorUpdated", action: self.competitorUpdated)
        self.competitors?.events.listenTo("competitorRemoved", action: self.competitorRemoved)
        
        self.activityManager = CMMotionActivityManager()
        self.pedoMeter = CMPedometer()

        // disable the interactivePopGestureRecognizer so you cant slide from left to pop the current view
        if self.navigationController!.respondsToSelector(Selector("interactivePopGestureRecognizer")) {
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
        
        return self.competitors?.list.count ?? 0
        
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        return true
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellIdentifier = "CompetitorsTableViewCell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! CompetitorsTableViewCell
            
        if let competitor = self.competitors?.list[indexPath.row] {
            
            cell.positionLabel.text = competitor.getPosition(indexPath.row)
            cell.nameLabel.text = competitor.name?.uppercaseString
            cell.distancePaceLabel.text = String(format: "%6.2f km", competitor.distance ?? 0.00)
            cell.profileImage.image = competitor.image
            
        }
        
        return cell
        
    }
    
    func competitorAdded(data: Any?) {
        
        if let index = data as? Int {
                
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            
            dispatch_async(dispatch_get_main_queue()) {
            
                self.competitorsTableView.beginUpdates()
                
                self.competitorsTableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Middle)
                
                self.competitorsTableView.endUpdates()
            
            }
            
        }
        
        self.updateJoinRaceButton(0.5)
        
    }
    
    func competitorUpdated(data: Any?) {
        
        if let data = data as? NSDictionary, let currentIndex = data["index"] as? Int, let id = data["id"] as? String, let newIndex = self.competitors?.index(id) {
            
            let currentIndexPath = NSIndexPath(forRow: currentIndex, inSection: 0)
            let newIndexPath = NSIndexPath(forRow: newIndex, inSection: 0)
            
            self.competitorsTableView.beginUpdates()
            
            if newIndex != currentIndex {
                self.competitorsTableView.moveRowAtIndexPath(currentIndexPath, toIndexPath: newIndexPath)
            }
            
            self.competitorsTableView.endUpdates()
            
            dispatch_async(dispatch_get_main_queue()) {
                
                self.competitorsTableView.reloadRowsAtIndexPaths([newIndexPath], withRowAnimation: .None)
                
            }
            
        }
        
    }
    
    func competitorRemoved(data: Any?) {
        
        if let index = data as? Int {
            
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            
            dispatch_async(dispatch_get_main_queue()) {
            
                self.competitorsTableView.beginUpdates()
                
                self.competitorsTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Middle)
                
                self.competitorsTableView.endUpdates()
                
            }
            
        }
        
        self.updateJoinRaceButton(0.5)
        
    }
    
    // MARK: Actions
    
    @IBAction func joinButtonPressed(sender: UIButton) {
        
        if let userId = self.currentUserId {
            
            if self.competitors?.findOne(userId) != nil {
                
                self.competitors?.remove(userId)
                
            } else {
                
                self.competitors?.insert(userId)
                
            }
            
        }
        
    }
    
    @IBAction func startStopPressed(sender: AnyObject) {
        
        if myLocationManager == nil {
            
            self.willStartRace()
            
        } else {
            
            self.willStopRace()
            
        }
        
    }
    
    func updateJoinRaceButton(duration: Double) {
        
        dispatch_async(dispatch_get_main_queue()) {
            
            if let userId = self.currentUserId {
                
                if self.competitors?.index(userId) != nil {
                    
                    self.joinRaceButton.setTitle("LEAVE RACE", forState: .Normal)
                    
                    UIView.animateKeyframesWithDuration(duration, delay: 0, options: [], animations: { self.startStopButton.alpha = 1 }, completion: nil)
                    
                    self.startStopButton.enabled = true
                    
                } else {
                    
                    self.joinRaceButton.setTitle("JOIN RACE", forState: .Normal)
                    
                    UIView.animateKeyframesWithDuration(duration, delay: 0, options: [], animations: { self.startStopButton.alpha = 0.5 }, completion: nil)
                    
                    self.startStopButton.enabled = false
                    
                }
                
            }
            
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
    
    func receiveAltimeterNotification(notification:NSNotification) {
        
        let userInfo:NSDictionary = notification.userInfo!
        let altimeterData:CMAltitudeData? = userInfo.objectForKey("Altimeter") as? CMAltitudeData
        
        if let data = altimeterData {
            self.pressure = Double(data.pressure)
            self.altitude = Double(data.relativeAltitude)
        }
        
    }
    
    func receiveLocationNotification(notification: NSNotification) {
        
        let userInfo: NSDictionary = notification.userInfo!
        let location: CLLocation? = userInfo.objectForKey("Location") as? CLLocation
        
        if let loc = location  {
            
            self.bLocationsReceived = true
            
            self.lat = loc.coordinate.latitude
            self.lon = loc.coordinate.longitude
            
            if let lMgr = myLocationManager {
                
                self.speed = lMgr.getStableSpeed() * 3.6
                self.distance = lMgr.getDistance() / 1000
                self.durationString = lMgr.getDuration()
                self.duration = lMgr.getDurationDouble()
                
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                
                self.durationLabel.text = self.durationString
                self.speedLabel.text = String(format: "%6.2f kph", self.speed)
                self.raceDistanceLabel.text = String(format: "%6.2f km", self.distance)
                
            }
            
            if let id = self.currentUserId {
                
                let fields = [
                    "distance": self.distance,
                    "pace": self.currentPace
                ]
                
                self.competitors?.update(id, fields: fields)
                
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
        
//        let voice = AVSpeechSynthesizer()
//        let myUtterance = AVSpeechUtterance(string: "Your race has begun")
//        voice.speakUtterance(myUtterance)

        // Hide the back button incase the user accidently hits it
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.bLocationsReceived = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RaceRecordViewController.receiveLocationNotification), name: "locationNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RaceRecordViewController.receiveAltimeterNotification), name: "altimeterNotification", object: nil)

        geoEvents = []
        myLocationManager = SharedLocationManager.sharedInstance
        myLocationManager?.workInBackground(true)
        myLocationManager?.resetDistance()
        
        self.runDetailObject = writeRaceDetail()
        
        // Start a timer that will run the updateLog function once every second
        self.logTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(RaceRecordViewController.updateLog), userInfo: nil, repeats: true)
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
                        
                        if(error == nil) {
                            
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
                                    
                                    let paceStr = String(self.currentPace * 16.6667)
                                    let paceArr = paceStr.componentsSeparatedByString(".")
                                    let minutes = Int(paceArr[0])
                                    let seconds = Int(paceArr[1])
                                    
                                    self.paceLabel.text = String(format:"%02d' %02d\"", minutes!, seconds!)
                                    
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
