//
//  UIGraphView.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 25/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

class UIGraphView: UIView {
    var yMax:CGFloat = 0.0
    var dataPoints: [Double] = []
    var lineColor = UIColor.redColor()
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
        if let context = UIGraphicsGetCurrentContext() {
            self.layer.borderWidth = 2
            self.layer.cornerRadius = 12
            self.layer.masksToBounds = true
            self.layer.borderColor = UIColor.blackColor().CGColor
            self.drawGrid(context)
            self.drawLine(context, pointsArray: dataPoints, lineColor: lineColor)
        }
    }
    
    func drawGrid(context:CGContextRef) {
        var scaledPoint:CGFloat = 0.0
        let path = CGPathCreateMutable()
        for var y = 1 ; y<Int(yMax) ; y++ {
            scaledPoint = (CGFloat(self.bounds.size.height) / self.yMax) * CGFloat(y)
            CGPathMoveToPoint(path, nil, 0.0, floor(self.bounds.size.height - scaledPoint)+0.5)
            CGPathAddLineToPoint(path,nil,CGFloat(self.bounds.size.width-1),floor(self.bounds.size.height - scaledPoint)+0.5)
        }
        CGContextBeginPath(context)
        CGContextAddPath(context, path)
        CGContextSetLineWidth(context,0.5)
        CGContextSetStrokeColorWithColor(context,UIColor.lightGrayColor().CGColor)
        CGContextStrokePath(context)
    }
    
    func drawLine(context:CGContextRef, pointsArray:[Double], lineColor:UIColor)
    {
        if pointsArray.count == 0 {
            return
        }
    
        var scaledPoint:CGFloat = 0.0
        var x:CGFloat = 0.0
        let path = CGPathCreateMutable()
        let startPoint = pointsArray[0]
        if startPoint <= 0 {
            scaledPoint = 0.0
        }
        else {
            scaledPoint = (CGFloat(self.bounds.size.height) / self.yMax) * CGFloat(startPoint)
        }
        CGPathMoveToPoint(path, nil, floor(x)+0.5, floor(self.bounds.size.height - scaledPoint)+0.5)
        let xDelta:CGFloat = CGFloat(self.bounds.size.width-1) / CGFloat(pointsArray.count)
        for point in pointsArray {
            if(point <= 0) {
                scaledPoint = 0.0
            }
            else {
                scaledPoint = (CGFloat(self.bounds.size.height) / self.yMax) * CGFloat(point)
            }
            CGPathAddLineToPoint(path,nil,floor(x)+0.5,floor(self.bounds.size.height - scaledPoint)+0.5)
            x += xDelta
        }
        CGContextBeginPath(context)
        CGContextAddPath(context, path)
        CGContextSetLineWidth(context,1.0)
        CGContextSetStrokeColorWithColor(context,lineColor.CGColor)
        CGContextStrokePath(context)
    }

}
