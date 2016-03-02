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
     
        let color1 = UIColor(red: 0.115, green: 0.115, blue: 0.115, alpha: 1).CGColor
        let color2 = UIColor.blackColor().CGColor
        
        let gradientColors = [color1, color2, color1]
        let gradientLocations = [0.0, 0.5, 1.0]
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = button.bounds
        gradientLayer.colors = gradientColors
        gradientLayer.locations = gradientLocations
        
        button.layer.insertSublayer(gradientLayer, atIndex: 0)
        button.layer.shadowOffset = CGSizeMake(0, 0)
        button.layer.shadowRadius = 5
        button.layer.shadowOpacity = 0.5
        
        button.clipsToBounds = true
    
    }
    
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
