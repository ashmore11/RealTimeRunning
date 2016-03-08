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
    
    @IBOutlet weak var averagePaceLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var averageSpeedLabel: UILabel!
    @IBOutlet weak var totalStepsLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var raceNameLabel: UILabel!
    
    @IBOutlet weak var raceLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        setViewGradient(self.view)
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            self.managedObjectContext = delegate.managedObjectContext
        }
        getRunSummaryData()
        
        if let context = self.managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: "RunData")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: true)]
            fetchRequest.predicate = NSPredicate(format:"runDataToRunDetail = %@", self.runDetail!)
            
            do {
                //let result = try context.executeFetchRequest(fetchRequest)
                let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) {
                    results in
                    
                    if let results = results.finalResult {
                        for rundata in results  {
                            if let data = rundata as? RunData {
                                if let lat = data.lattitude, let lon = data.longitude {
                                    let x = CLLocationCoordinate2DMake(Double(lat), Double(lon))
                                    self.geoEvents.append(x)
                                }
                            }
                        }
                        dispatch_async(dispatch_get_main_queue()) {
                        }
                    }
                }
                try context.executeRequest(asyncRequest)
                
            } catch {
                let fetchError = error as NSError
                logError("Error while getting race data for Map display: \(fetchError.description)")
            }
        }

    }
    
    // This will redraw the gradient layer after a rotation
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        self.view.layer.sublayers?.first?.frame = self.view.bounds
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
    
    func getRunSummaryData() {
        // Create an array of AnyObject since it needs to contain multiple types
        if let context = self.managedObjectContext {
            var expressionDescriptions = [AnyObject]()
            
            var expressionDescription = NSExpressionDescription()
            expressionDescription.name = "averageSpeed"
            expressionDescription.expression = NSExpression(format: "@avg.speed")
            expressionDescription.expressionResultType = .DoubleAttributeType
            expressionDescriptions.append(expressionDescription)
            
            expressionDescription = NSExpressionDescription()
            expressionDescription.name = "averagePace"
            expressionDescription.expression = NSExpression(format: "@avg.currentPace")
            expressionDescription.expressionResultType = .DoubleAttributeType
            expressionDescriptions.append(expressionDescription)
            
            expressionDescription = NSExpressionDescription()
            expressionDescription.name = "totalDistance"
            expressionDescription.expression = NSExpression(format: "@max.distance")
            expressionDescription.expressionResultType = .DoubleAttributeType
            expressionDescriptions.append(expressionDescription)

            expressionDescription = NSExpressionDescription()
            expressionDescription.name = "totalSteps"
            expressionDescription.expression = NSExpression(format: "@max.stepsTaken")
            expressionDescription.expressionResultType = .Integer64AttributeType
            expressionDescriptions.append(expressionDescription)
           
            expressionDescription = NSExpressionDescription()
            expressionDescription.name = "pedDistance"
            expressionDescription.expression = NSExpression(format: "@max.pedDistance")
            expressionDescription.expressionResultType = .DoubleAttributeType
            expressionDescriptions.append(expressionDescription)

            expressionDescription = NSExpressionDescription()
            expressionDescription.name = "timeStampFirst"
            expressionDescription.expression = NSExpression(format: "@min.timeStamp")
            expressionDescription.expressionResultType = .DateAttributeType
            expressionDescriptions.append(expressionDescription)

            expressionDescription = NSExpressionDescription()
            expressionDescription.name = "timeStampLast"
            expressionDescription.expression = NSExpression(format: "@max.timeStamp")
            expressionDescription.expressionResultType = .DateAttributeType
            expressionDescriptions.append(expressionDescription)
            
            let request = NSFetchRequest(entityName: "RunData")
            request.resultType = .DictionaryResultType
            request.propertiesToFetch = expressionDescriptions
            request.predicate = NSPredicate(format:"runDataToRunDetail = %@", self.runDetail!)
           
            // Perform an Async fetch
            do {
                let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: request) {
                    results in
                    if let results = results.finalResult {
                        let dict = results[0] as! [String:AnyObject]
                        let averageSpeed = dict["averageSpeed"]! as! Double
                        let averagePace = dict["averagePace"]! as! Double
                        let totalDistance = dict["totalDistance"]! as! Double
                        let totalSteps = dict["totalSteps"]! as! Int
                        //let pedDistance = dict["pedDistance"]! as! Double
                        let sDate = dict["timeStampFirst"]! as? NSDate
                        let eDate = dict["timeStampLast"]! as? NSDate
                        var myRaceTime:String = ""
                        if let sd = sDate,let ed = eDate {
                            myRaceTime = stringFromTimeInterval(ed.timeIntervalSinceDate(sd))
                        }
                     
                        dispatch_async(dispatch_get_main_queue()) {
                            let dateFormatter = NSDateFormatter()
                            dateFormatter.dateFormat = "d MMM y"
                            var formattedDate = "Unset"
                            var raceName = "Unset"
                            if let raceDate = self.runDetail!.date {
                                formattedDate = dateFormatter.stringFromDate(raceDate) // if date conversion fails this returns nil and that's OK
                            }
                            if let name = self.runDetail!.name {
                                raceName = name
                            }
                            self.raceNameLabel.text = String(format:"Race: %@ %@",formattedDate,raceName)
                            self.averageSpeedLabel.text = String(format: "Average Speed: %6.2f Kph",averageSpeed  * 3.6)
                            self.averagePaceLabel.text = String(format: "Pace: %6.2f Min. / Km",(averagePace * 1000.0) / 60.0)
                            self.distanceLabel.text = String(format: "Distance: %6.2f Meters",totalDistance)
                            self.totalStepsLabel.text = String(format: "Total Steps: %d",totalSteps)
                            self.timeLabel.text = String(format: "Race Time: %@",myRaceTime)
                        }
                    }
                }
                try context.executeRequest(asyncRequest)
            } catch {
                let fetchError = error as NSError
                logError(fetchError.description)
            }
        }
    }

}
