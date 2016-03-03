//
//  raceHistorySummaryViewController.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 25/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class raceHistorySummaryViewController: UIViewController {
    var managedObjectContext: NSManagedObjectContext!
    var runDetail:RunDetail?
    var geoEvents:[CLLocationCoordinate2D] = []
    var averageSpeed = 0.0
    var totaldistance = 0.0
    var totalSteps = 0
    var totalSpeed = 0.0
    var raceTime:String = ""
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var averageSpeedLabel: UILabel!
    @IBOutlet weak var totalStepsLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        setViewGradient(self.view)
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            self.managedObjectContext = delegate.managedObjectContext
        }
        
        // Get data for the race and summerise it
        if let context = self.managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: "RunData")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: true)]
            fetchRequest.predicate = NSPredicate(format:"runDataToRunDetail = %@", self.runDetail!)
            
            do {
                let result = try context.executeFetchRequest(fetchRequest)
                
                for rundata in result  {
                    if let data = rundata as? RunData {
                        if let steps = data.stepsTaken {
                            totalSteps = Int(steps)
                        }
                        if let speed = data.speed {
                            totalSpeed += Double(speed)
                        }

                        if let distance = data.distance {
                            totaldistance = Double(distance)
                        }
                        if let lat = data.lattitude, let lon = data.longitude {
                            let x = CLLocationCoordinate2DMake(Double(lat), Double(lon))
                            geoEvents.append(x)
                        }
                    }
                }
                if result.count > 1 {
                    let first = result.first as! RunData
                    let sDate = first.timeStamp
                    let last = result.last as! RunData
                    let eDate = last.timeStamp
                    if let sd = sDate,let ed = eDate {
                        raceTime = stringFromTimeInterval(ed.timeIntervalSinceDate(sd))
                    }
                }
                
                if(result.count > 1) {
                averageSpeed = totalSpeed / Double(result.count)
                averageSpeedLabel.text = String(format: "Average Speed: %6.2f Kph",averageSpeed  * 3.6)
                }
                else {
                    averageSpeedLabel.text = "Average Speed: Unset"
                }
                distanceLabel.text = String(format: "Distance: %6.2f Meters",totaldistance)
                totalStepsLabel.text = String(format: "Total Steps: %d",totalSteps)
                timeLabel.text = String(format: "Race Time: %@",raceTime)
                
            } catch {
                let fetchError = error as NSError
                print(fetchError)
            }
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showMap" {
            if let controller = segue.destinationViewController as? MapViewController {
                controller.geoEvents = geoEvents
            }
        }
        if segue.identifier == "showRaw" {
            if let controller = segue.destinationViewController as? RawRaceDataTableViewController {
                controller.runDetail = self.runDetail
            }
        }
        if segue.identifier == "showGraph" {
            if let controller = segue.destinationViewController as? RaceGraphViewController {
                controller.runDetail = self.runDetail
            }
        }

    }

}
