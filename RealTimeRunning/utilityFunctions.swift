//
//  utilityFunctions.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 25/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD
import CoreData

func stringFromTimeInterval(interval:NSTimeInterval) -> String {
    let ti = NSInteger(interval)
    let seconds = ti % 60
    let minutes = (ti / 60) % 60
    let hours = (ti / 3600)
    return String(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
}

func degreesToRadian(x: Double) -> Double {
    return (M_PI * x / 180.0)
}

func radiansToDegrees(x: Double) -> Double {
    return (180.0 * x / M_PI)
}

func getDocumentsDirectory() -> NSString {
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
    let documentsDirectory = paths[0]
    return documentsDirectory
}

extension UIView {
    
    func uiViewContentToImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.mainScreen().scale)
        drawViewHierarchyInRect(self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let data = UIImageJPEGRepresentation(image, 0.8) {
            let filename = getDocumentsDirectory().stringByAppendingPathComponent("temp.png")
            data.writeToFile(filename, atomically: true)
            
        }
        
        return image
    }
}

func setViewGradient(view: UIView) {
    
    let color1 = UIColor(red: 0.878, green: 0.517, blue: 0.258, alpha: 1.0).CGColor as CGColorRef
    let color2 = UIColor(red: 0.592, green: 0.172, blue: 0.070, alpha: 1.0).CGColor as CGColorRef
    
    let gradientLayer = CAGradientLayer()
    gradientLayer.frame = view.bounds
    gradientLayer.colors = [color1, color2]
    gradientLayer.locations = [0.0, 0.7]
    
    view.layer.insertSublayer(gradientLayer, atIndex: 0)
    
}

func setTableViewBackgroundGradient(sender: UITableViewCell, topColor: UIColor, bottomColor: UIColor) {
    
    let gradientBackgroundColors = [topColor.CGColor, bottomColor.CGColor]
    let gradientLocations = [0.0, 1.0]
    
    let gradientLayer = CAGradientLayer()
    gradientLayer.colors = gradientBackgroundColors
    gradientLayer.locations = gradientLocations
    
    gradientLayer.frame = sender.bounds
    let backgroundView = UIView(frame: sender.bounds)
    backgroundView.layer.insertSublayer(gradientLayer, atIndex: 0)
    sender.backgroundView = backgroundView
    
}

func setButtonGradient(buttons: UIButton...) {
    
    for button in buttons {
     
        let color1 = UIColor(red: 0.100, green: 0.100, blue: 0.100, alpha: 1).CGColor
        let color2 = UIColor.blackColor().CGColor
        
        let gradientColors = [color1, color2, color1]
        let gradientLocations = [0.0, 0.4, 1.0]
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = button.bounds
        gradientLayer.colors = gradientColors
        gradientLayer.locations = gradientLocations
        
        button.layer.insertSublayer(gradientLayer, atIndex: 0)
        
        button.clipsToBounds = true
    
    }
    
}

func showActivityIndicator(view: UIView, text: String?) {

    dispatch_async(dispatch_get_main_queue()) {
        
        let loadingNotification = MBProgressHUD.showHUDAddedTo(view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Indeterminate
        
        if text != nil {
            loadingNotification.labelText = text
            loadingNotification.labelFont = UIFont(name: "Oswald-Regular", size: 20)
        }
        
    }
    
}

func hideActivityIndicator(view: UIView) {
    
    dispatch_async(dispatch_get_main_queue()) {
    
        MBProgressHUD.hideAllHUDsForView(view, animated: true)
        
    }
    
}

func logError(errorString:String)  {
    
    if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
        let context = delegate.managedObjectContext
        
        if let logObject = NSEntityDescription.insertNewObjectForEntityForName("ErrorLog", inManagedObjectContext: context) as? ErrorLog {
            logObject.logDate = NSDate()
            logObject.logMessage = errorString
            
            do {
                
                try context.save()
                
            } catch {
                
                fatalError("Failure to save context: \(error)")
                
            }
            
        }
        
    }
    

}

extension String {
    func appendLineToURL(fileURL: NSURL) throws {
        //try self.stringByAppendingString("\n").appendToURL(fileURL)
        try self.appendToURL(fileURL)
    }
    
    func appendToURL(fileURL: NSURL) throws {
        let data = self.dataUsingEncoding(NSUTF8StringEncoding)!
        try data.appendToURL(fileURL)
    }
}

extension NSData {
    func appendToURL(fileURL: NSURL) throws {
        if let fileHandle = try? NSFileHandle(forWritingToURL: fileURL) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.writeData(self)
        }
        else {
            try writeToURL(fileURL, options: .DataWritingAtomic)
        }
    }
}

func readSettingsFromDb() ->Settings?  {
    var settings:Settings? = nil
    if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
        let managedObjectContext:NSManagedObjectContext? = delegate.managedObjectContext
        if let context = managedObjectContext {
            
            do {
                let fetchRequest = NSFetchRequest(entityName: "Settings")
                fetchRequest.fetchLimit = 1
                let result = try context.executeFetchRequest(fetchRequest)
                if result.count > 0 {
                    let rundata = result[0]
                    if let object = rundata as? Settings {
                        settings = object
                    }
                }
                else {
                    if let newObject = NSEntityDescription.insertNewObjectForEntityForName("Settings", inManagedObjectContext: context) as? Settings {
                        newObject.displayUnits = "metric"
                        newObject.loggingFrequency = 1
                        try context.save()
                        settings = newObject
                    }
                }
            } catch {
                let fetchError = error as NSError
                logError("Error while reading settings data: \(fetchError.description)")
            }
        }
    }
    return settings
}

func conversionFactorSpeed() -> (factor:Double, desc:String, displayUnits:String) {
    var factor = 1.0
    var desc = "M/S"
    var displayUnits = "Native"
    if let settings = readSettingsFromDb() {
        if settings.displayUnits == "metric" {
            factor = 3.6
            desc = "Kph"
            displayUnits = "metric"
        }
        else {
            factor = 2.23694
            desc = "MPH"
            displayUnits = "imperial"
        }
    }
    
    return (factor:factor, desc:desc, displayUnits:displayUnits)
}

func conversionFactorPace() -> (factor:Double, desc:String, displayUnits:String) {
    var factor = 1.0
    var desc = "S/M"
    var displayUnits = "Native"
    if let settings = readSettingsFromDb() {
        if settings.displayUnits == "metric" {
            factor = 16.6667
            desc = "Min./Km"
            displayUnits = "metric"
        }
        else {
            factor = 26.8224
            desc = "Min/Mile"
            displayUnits = "imperial"
        }
    }
    
    return (factor:factor, desc:desc, displayUnits:displayUnits)
}

// Helper function to convert from RGB to UIColor
func UIColorFromRGB(rgbValue: UInt) -> UIColor {
    
    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
    
}

func getOrdinalPosition(index: Int) -> String {
    
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .OrdinalStyle
    
    guard let position = formatter.stringFromNumber(index + 1) else { return "" }
        
    return position
    
}

