//
//  RaceGraphViewController.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 25/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class RaceGraphViewController: UIViewController {
    var managedObjectContext: NSManagedObjectContext!
    var runDetail:RunDetail?
    var geoEvents:[CLLocationCoordinate2D] = []
    var averageSpeed = 0.0
    var totaldistance = 0.0
    var totalSteps = 0
    var totalSpeed = 0.0
    var topSpeed = 0.0
    var raceTimeInSeconds = 0
    var speedArray:[Double] = []

    @IBOutlet weak var graphView: UIGraphView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            self.managedObjectContext = delegate.managedObjectContext
        }
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
                            topSpeed = (Double(speed) > topSpeed) ? Double(speed) : topSpeed
                            speedArray.append(Double(speed)  * 3.6)
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
                // Convert from meters per second to kilometers per hour
                topSpeed = topSpeed * 3.6
                // Give the graph some headroom
                topSpeed = topSpeed * 1.2
                if result.count > 1 {
                    let first = result.first as! RunData
                    let sDate = first.timeStamp
                    let last = result.last as! RunData
                    let eDate = last.timeStamp
                    if let sd = sDate,let ed = eDate {
                        raceTimeInSeconds = Int(ed.timeIntervalSinceDate(sd))
                    }
                }
                
                averageSpeed = totalSpeed / Double(result.count)
                self.graphView.yMax = CGFloat(topSpeed)
                self.graphView.dataPoints = speedArray
            } catch {
                let fetchError = error as NSError
                logError(fetchError.description)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
