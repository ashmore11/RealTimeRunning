//
//  utilityFunctions.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 25/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import Foundation
import UIKit

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