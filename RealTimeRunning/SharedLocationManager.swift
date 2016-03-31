//
//  SharedLocationManager.swift
//  navMyRun
//
//  Created by bob.ashmore on 18/02/2016.
//  Copyright © 2016 bob.ashmore. All rights reserved.
//
//   ***************** For GPS Background Logging to Work *******************
// The following key must be added manually to the info.plist file
// <key>NSLocationAlwaysUsageDescription</key> <string>Required for logging GPS data</string>
// Also under Background Modes in Capabilities you must tick Location Updates box after
// changing allow background modes to YES

// This class conformas to the Sigleton pattern so only one instance is created for the app


// To use GPS in any class in your app just add the following lines

// myLocationManager = SharedLocationManager.sharedInstance
// NSNotificationCenter.defaultCenter().addObserver(self, selector:"receiveLocationNotification:", name:"locationNotification", object:nil)


/* To get the location data into your controller add this function

func receiveLocationNotification(notification:NSNotification) {
    let userInfo:NSDictionary = notification.userInfo!
    let location:CLLocation? = userInfo.objectForKey("Location") as? CLLocation
    let newHeading:CLHeading? = userInfo.objectForKey("Heading") as? CLHeading
    
    if let loc = location  {
        let lat = loc.coordinate.latitude
        let lon = loc.coordinate.longitude
        let speed = loc.speed
        let distance = (myLocationManager?.getDistance())!
        let durationString = (myLocationManager?.getDuration())!
        let duration = (myLocationManager?.getDurationDouble())!
        print("lat: \(self.lat) lon: \(self.lon) distance: \(self.distance) duration: \(self.duration)")
    }
    if let hdr = newHeading {
        let heading = hdr.magneticHeading
        print("Heading: \(self.heading)")
    }
}
*/

import UIKit
import CoreLocation
import CoreMotion

class SharedLocationManager:NSObject,CLLocationManagerDelegate {
    static let sharedInstance = SharedLocationManager()

    var locationManager:CLLocationManager?
    var location:CLLocation?
    var currentHeading:CLHeading?
    let savedMagneticHeading = 0.0
    let savedTrueHeading = 0.0
    var currentVariation = 0.0
    var savedLocation:CLLocation?
    var bKeepAlive:Bool = false
    var altitudeManager:CMAltimeter?
    var bAltitudeAvailable:Bool = false
    var distanceTravelled = 0.0
    var startTime:NSDate?
    var avgSpeedQueue:[Double] = []
    let queueSize = 20 // Tthe stable speed will return the average of the last 20 speed readings
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
    
    override init () {
        super.init()
        self.location = nil
        self.currentHeading = nil
        self.savedLocation = nil
        self.distanceTravelled = 0.0
        self.startTime = NSDate()
        
        self.locationManager = CLLocationManager()
        if let lm = self.locationManager {
            lm.desiredAccuracy = kCLLocationAccuracyBest
            lm.activityType    = .OtherNavigation
            lm.distanceFilter  = kCLDistanceFilterNone
            lm.delegate        = self
            lm.requestAlwaysAuthorization()
            lm.allowsBackgroundLocationUpdates = true
            
            // Setup & Start Compass service
            //lm.headingFilter      = 1.0
            //lm.headingOrientation = .Portrait
            //lm.startUpdatingHeading()
            
            // If the hardware has an barometer the setup and use it
            if NSClassFromString("CMAltimeter") != nil {
                if CMAltimeter.isRelativeAltitudeAvailable() == true {
                    self.altitudeManager = CMAltimeter()
                    self.bAltitudeAvailable = true
                    self.altitudeManager!.startRelativeAltitudeUpdatesToQueue(NSOperationQueue.mainQueue(), withHandler: { data, error in
                        if error == nil {
                            if let altimeterData:CMAltitudeData = data {
                                let altitude:CMAltitudeData = altimeterData.copy() as! CMAltitudeData
                                NSNotificationCenter.defaultCenter().postNotificationName("altimeterNotification", object:nil, userInfo:["Altimeter":altitude])
                            }
                        }
                    })
                }
            }
            // Listen for background notifications
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SharedLocationManager.receiveBackgroundNotification), name:"backgroundNotification", object:nil)
        }
        self.bKeepAlive = false
        self.bAltitudeAvailable = false
    }
    
    // The GPS Chip has data to give us
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.last {
            let eventDate = currentLocation.timestamp
            let howRecent = eventDate.timeIntervalSinceNow
            // if the reading from the GPS is older than 10 Seconds
            // then I will discard it
            if fabs(howRecent) > 10.0 {
                return
            }
            // Calculate the distance travelled since the last reading
            if self.savedLocation != nil {
                self.distanceTravelled += currentLocation.distanceFromLocation(self.savedLocation!)
            }
            // save the current reading for the above distance travelled calculation
            self.savedLocation = locations.last
            // Need to keep an array of the last number of speed readings so
            // we can return the average speed
            avgSpeedQueue.append(currentLocation.speed)
            if avgSpeedQueue.count > queueSize {
                avgSpeedQueue.removeAtIndex(0)
            }
            // Post the new location data out to all listners
            dispatch_async(dispatch_get_main_queue()) {
                NSNotificationCenter.defaultCenter().postNotificationName("locationNotification", object:nil, userInfo:["Location":currentLocation.copy()])
            }
        }
    }
    
    // The Compass has data to give us
    func locationManager(manager:CLLocationManager, didUpdateHeading heading:CLHeading) {
        self.currentHeading = heading.copy() as? CLHeading
        dispatch_async(dispatch_get_main_queue()) {
            if let newHeading:CLHeading = heading.copy() as? CLHeading {
                let eventDate = newHeading.timestamp
                let howRecent = eventDate.timeIntervalSinceNow
                //Is the event recent and accurate enough ?
                if fabs(howRecent) > 2.0 {
                    return
                }
                // I calculate and keep the current variation if the user requires it
                self.currentVariation = newHeading.magneticHeading - newHeading.trueHeading
                if(newHeading.headingAccuracy >= 0) {
                    NSNotificationCenter.defaultCenter().postNotificationName("locationNotification", object:nil, userInfo:["Heading":newHeading])
                }
            }
        }
    }

    // Return true if compass calibration required
    func locationManagerShouldDisplayHeadingCalibration(manager:CLLocationManager) ->Bool {
        if self.currentHeading == nil {
            return true // Got nothing, We can assume we have to calibrate.
        }
        else if self.currentHeading!.headingAccuracy < 0  {
            return true // Negative numbers mean invalid heading. we probably need to calibrate
        }
        else if self.currentHeading!.headingAccuracy > 5  {
            return true // 5 degrees is OK.
        }
        return false // Compass is OK.
    }
    
    // This delegate method is invoked when the location managed encounters an error condition.
    func locationManager(manager:CLLocationManager, didFailWithError error:NSError) {
        NSNotificationCenter.defaultCenter().postNotificationName("locationNotification", object:nil, userInfo:["Error":error])
        /*
        if error.code == CLError.Denied.rawValue {
            // This error indicates that the user has denied the application's request to use location services.
            print("DEBUG Location error:Location services denied")
            manager.stopUpdatingHeading()
        } else if error.code == CLError.HeadingFailure.rawValue {
            // This error indicates that the heading could not be determined, most likely because of strong magnetic interference.
            print("DEBUG Location error:Heading cannot be determined")
        } else {
            print("DEBUG Location error:%@",error.description)
        }
        */
        var errString = ""
        switch error.code {
        case CLError.LocationUnknown.rawValue:
            errString = "The location manager was unable to obtain a location value right now."
        case CLError.Denied.rawValue:
            errString = "Access to the location service was denied by the user."
            manager.stopUpdatingHeading()
        case CLError.Network.rawValue:
            errString = "The network was unavailable or a network error occurred."
        case CLError.HeadingFailure.rawValue:
            errString = "The heading could not be determined."
        case CLError.RegionMonitoringDenied.rawValue:
            errString = "Access to the region monitoring service was denied by the user."
        case CLError.RegionMonitoringFailure.rawValue:
            errString = "A registered region cannot be monitored."
        case CLError.RegionMonitoringSetupDelayed.rawValue:
            errString = "Core Location could not initialize the region monitoring feature immediately."
        case CLError.RegionMonitoringResponseDelayed.rawValue:
            errString = "Core Location will deliver events but they may be delayed."
        case CLError.GeocodeFoundNoResult.rawValue:
            errString = "The geocode request yielded no result."
        case CLError.GeocodeFoundPartialResult.rawValue:
            errString = "The geocode request yielded a partial result."
        case CLError.GeocodeCanceled.rawValue:
            errString = "The geocode request was canceled."
        case CLError.DeferredFailed.rawValue:
            errString = "The location manager did not enter deferred mode for an unknown reason. GPS may be unavialable"
        case CLError.DeferredNotUpdatingLocation.rawValue:
            errString = "The location manager did not enter deferred mode because location updates were already disabled or paused."
        case CLError.DeferredAccuracyTooLow.rawValue:
            errString = "Deferred mode is not supported for the requested accuracy."
        case CLError.DeferredDistanceFiltered.rawValue:
            errString = "Deferred mode does not support distance filters."
        case CLError.DeferredCanceled.rawValue:
            errString = "The request for deferred updates was canceled by your app or by the location manager."
        case CLError.RangingUnavailable.rawValue:
            errString = "Ranging is disabled."
        case CLError.RangingFailure.rawValue:
            errString = "A general ranging error occurred."
        default:
            errString = "An unknown error has occured"
        }
        logError(errString)
    }

    func getVariation() -> Double {
        return self.currentVariation
    }
    
    func getLastSavedLocation() -> CLLocation? {
        return self.savedLocation
    }
    
    func workInBackground(bBackground:Bool) {
        self.bKeepAlive = bBackground
    }
    
    func resetDistance() {
        self.startTime = NSDate()
        self.distanceTravelled = 0.0
    }
 
    func getDistance() ->Double {
        return self.distanceTravelled
    }

    func getDuration() ->String {
        if let sTime = self.startTime {
            let diffDateComponents = NSCalendar.currentCalendar().components([.Hour, .Minute, .Second], fromDate: sTime, toDate: NSDate(), options: NSCalendarOptions.init(rawValue: 0))
            return String(format: "%02d:%02d:%02d", diffDateComponents.hour,diffDateComponents.minute,diffDateComponents.second)
        }
        return ""
    }

    func getDurationDouble() ->Double {
        if let sTime = self.startTime {
            let diffDateComponents = NSCalendar.currentCalendar().components([.Hour, .Minute, .Second], fromDate: sTime, toDate: NSDate(), options: NSCalendarOptions.init(rawValue: 0))
            let duration =  Double(diffDateComponents.hour) + (Double(diffDateComponents.minute) / 60.0) + (Double(diffDateComponents.second) / 3600.0)
            return duration
        }
        return 0.0
    }
    
    func getStableSpeed() ->Double {
        if avgSpeedQueue.count == 0 {
            return 0.0
        }
        return avgSpeedQueue.reduce(0) { $0 + $1 } / Double(avgSpeedQueue.count)
    }

    func receiveBackgroundNotification(notification:NSNotification) {
        //let userInfo:NSDictionary = notification.userInfo!
        if let userInfo:[String:String] = notification.userInfo as? [String:String] {
            if let backgroundMode:String = userInfo["BackGroundMode"] {
                //let backgroundMode:String = userInfo.objectForKey("BackGroundMode") as! String
                
                if backgroundMode == "BackGround" {
                    if self.bKeepAlive == false {
                        self.locationManager!.stopUpdatingLocation()
                        self.locationManager!.stopUpdatingHeading()
                    }
                }
                else {
                    if self.bKeepAlive == false {
                        self.locationManager!.startUpdatingLocation()
                        self.locationManager!.startUpdatingHeading()
                    }
                }
            }
        }
    }


}

