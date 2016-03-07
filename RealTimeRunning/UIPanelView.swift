//
//  UIPanelView.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 07/03/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

class UIPanelView: UIView {
    let startColor =  UIColor.darkGrayColor()
    let endColor   =  UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
    var faceGradient: CGGradientRef?

    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext();
        
        processGradient(context!, startColor: startColor, endColor: endColor, gradient: faceGradient)
        self.layer.borderWidth = 2
        self.layer.cornerRadius = 12
        self.layer.masksToBounds = true
        self.layer.borderColor = UIColor.blackColor().CGColor
    }
    
    
    func processGradient(context: CGContextRef, startColor: UIColor, endColor: UIColor, var gradient:CGGradientRef?) {
        if(gradient == nil) {
            let gradientColors: [AnyObject] = [startColor.CGColor, endColor.CGColor]
            let flocations: [CGFloat] = [ 0.0, 1.0 ]
            let rgbColorspace = CGColorSpaceCreateDeviceRGB()
            gradient = CGGradientCreateWithColors(rgbColorspace, gradientColors, flocations)
        }
        if let grad = gradient {
            CGContextDrawLinearGradient(context, grad, CGPointMake(self.bounds.size.width/2.0, 0), CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height),[])
        }
    }
    


}
