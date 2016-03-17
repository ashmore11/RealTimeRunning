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
    
    var userId: String?
    var race: Race!
    var competitors: [Competitor] = []
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
        
        let userInfo: NSDictionary = notification.userInfo!
        let location: CLLocation? = userInfo.objectForKey("Location") as? CLLocation

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
                
                if let userId = self.userId {
                
                    SocketIOManager.sharedInstance.sendPositionUpdate(userId, distance: self.distance, pace: self.currentPace)
                
                }
            
            }

        }
        
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.navigationItem.title = "RACE"
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "competitorsUpdated:", name: "competitorsUpdated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updatePosition:", name: "positionUpdateReceived", object: nil)
        
        self.competitorsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        competitorsTableView.delegate = self
        competitorsTableView.dataSource = self
        competitorsTableView.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.3)
        
        setViewGradient(self.view)
        setButtonGradient(startStopButton, joinRaceButton, raceDataButton, viewMapButton)
        statsViewArea.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.6)
        
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            
            self.managedObjectContext = delegate.managedObjectContext
        
        }
        
        if let race = self.race, let startTime = race.startTime {
            
            self.raceName = startTime
            self.title = self.raceName
            
        }
        
        self.getInitialCompetitors()
        self.updateJoinRaceButton(0)
        
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
        
        return self.competitors.count
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellIdentifier = "CompetitorsTableViewCell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! CompetitorsTableViewCell
        
        setTableViewBackgroundGradient(cell, topColor: UIColor(red: 0.100, green: 0.100, blue: 0.100, alpha: 1), bottomColor: UIColor.blackColor())
        
        let competitor = self.competitors[indexPath.row]
        
        cell.nameLabel.text = competitor.name.uppercaseString
        cell.positionLabel.text = competitor.position
        cell.profileImage.image = competitor.image
        
        return cell
        
    }
    
    func updateTableView(competitor: Competitor, insert: Bool) {
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.competitorsTableView.beginUpdates()
            
            if insert == true {
                
                self.competitors.append(competitor)
                
                if let index = self.competitors.indexOf({ $0.id == competitor.id }) {
                    
                    let indexPath = NSIndexPath(forRow: index, inSection: 0)
                
                    self.competitorsTableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Middle)
                
                }
            
            } else {
                
                if let index = self.competitors.indexOf({ $0.id == competitor.id }) {
                    
                    self.competitors.removeAtIndex(index)
                    
                    let indexPath = NSIndexPath(forRow: index, inSection: 0)
                    
                    self.competitorsTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Middle)
                    
                }
                
            }
            
            self.updateJoinRaceButton(0.5)
            
            self.competitorsTableView.endUpdates()
            
        }
        
    }
    
    func reloadCell(competitor: Competitor) {
        
        dispatch_async(dispatch_get_main_queue()) {
        
            if let index = self.competitors.indexOf({ $0.id == competitor.id }) {
            
                let indexPath = NSIndexPath(forRow: index, inSection: 0)
                
                self.competitorsTableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                
            }
            
        }
        
    }
    
    func getInitialCompetitors() {
    
        if let competitors = self.race.competitors {
            
            self.addCompetitors(competitors)
        
        }
        
    }
    
    func addCompetitors(ids: [String]) {
        
        let url = "http://real-time-running.herokuapp.com/api/users/"
        
        Alamofire.request(.PUT, url, parameters: ["ids": ids]).responseSwiftyJSON({ (request, response, json, error) in
            
            if let users = json.array {
                
                for user in users {
                    
                    if let id = user["fbid"].string,
                        let name = user["name"].string,
                        let imageURL = user["profileImage"].string,
                        let nsurl = NSURL(string: imageURL),
                        let data = NSData(contentsOfURL:nsurl),
                        let image = UIImage(data:data) {
                            
                            let competitor = Competitor(id: id, image: image, name: name)
                            
                            self.updateTableView(competitor, insert: true)
                            
                    }
                }
            }
            
            hideActivityIndicator(self.view)
        })
        
    }
    
    func addCompetitors(ids: String...) {
        
        self.addCompetitors(ids)
                
    }
    
    func removeCompetitor(id: String) {
        
        if let competitor = self.getCompetitor(id) {
            
            self.updateTableView(competitor, insert: false)
            
        }
        
        hideActivityIndicator(self.view)
        
    }
    
    func getCompetitor(id: String) -> Competitor? {
        
        if let index = self.competitors.indexOf({ $0.id == id }) {
            
            return self.competitors[index]
            
        } else {
            
            return nil
            
        }
        
    }
    
    // MARK: WebSockets
    
    func competitorsUpdated(notification: NSNotification) {
        
        if let items = notification.object, let id = items["userId"] as? String {
            
            if let competitor = getCompetitor(id) {
                
                self.removeCompetitor(competitor.id)

            } else {
                
                self.addCompetitors(id)
                
            }
        }
        
    }
    
    func updatePosition(notification: NSNotification) {
        
        if let items = notification.object, let id = items["id"] as? String, let distance = items["distance"] as? Double, let pace = items["pace"] as? Double, let competitor = getCompetitor(id) {
            
            self.competitors.sortInPlace { $0.distance > $1.distance }
            
            competitor.setDistance(distance)
            competitor.setPace(pace)
                
            if let index = self.competitors.indexOf({ $0.id == id }) {
            
                competitor.setPosition(index)
                
                self.reloadCell(competitor)
                
            }
        }
        
    }
    
    func updateJoinRaceButton(duration: Double) {
        
        dispatch_async(dispatch_get_main_queue()) {
        
            if let userId = self.userId {
                
                if self.getCompetitor(userId) != nil {
                    
                    self.joinRaceButton.setTitle("LEAVE RACE" , forState: .Normal)
                    
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
        
        if let userId = self.userId {
            
            SocketIOManager.sharedInstance.updateCompetitors(userId, raceId: self.race.id)
            
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
        
//        let voice = AVSpeechSynthesizer()
//        let myUtterance = AVSpeechUtterance(string: "Your race has begun")
//        voice.speakUtterance(myUtterance)

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
