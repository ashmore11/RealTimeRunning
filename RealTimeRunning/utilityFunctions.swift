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

func getStartTime(index: Int) -> String {
    
    let components = NSCalendar.currentCalendar().components([.Day, .Month, .Year, .Hour, .Minute, .Second ], fromDate: NSDate())
    components.minute = 0
    components.second = 0
    let startDate = NSCalendar.currentCalendar().dateFromComponents(components)
    
    components.setValue(index + 1, forComponent: .Hour);
    let startTime = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: startDate!, options: NSCalendarOptions(rawValue: 0))
    
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "HH:mm"
    
    let date = dateFormatter.stringFromDate(startTime!)
    
    return date
    
}

func showActivityIndicator(view: UIView, text: String?) {

    let loadingNotification = MBProgressHUD.showHUDAddedTo(view, animated: true)
    loadingNotification.mode = MBProgressHUDMode.Indeterminate
    loadingNotification.labelText = text ?? "Loading"
    
}

func hideActivityIndicator(view: UIView) {
    
    MBProgressHUD.hideAllHUDsForView(view, animated: true)
    
}
