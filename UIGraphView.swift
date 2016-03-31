//
//  UIGraphView.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 25/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

enum textAlignTypes {
    case ctAlignTopLeft
    case ctAlignTopCenter
    case ctAlignTopRight
    case ctAlignCenterLeft
    case ctAlignCenterCenter
    case ctAlignCenterRight
    case ctAlignBottomLeft
    case ctAlignBottomCenter
    case ctAlignBottomRight
}

class UIGraphView: UIView {
    var yMax:CGFloat = 0.0
    var dataPoints: [Double] = []
    var lineColor = UIColor.redColor()
    var graphHeader = "Speed (Kph)"
    var numeralColor = UIColor.whiteColor()
    var divSize:CGFloat = 0.0
    var topSize:CGFloat = 0.0
    let startColor =  UIColor.darkGrayColor()
    let endColor   =  UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
    var faceGradient: CGGradientRef?

    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
        if let context = UIGraphicsGetCurrentContext() {
            processGradient(context, startColor: startColor, endColor: endColor, gradient: faceGradient)

            self.layer.borderWidth = 2
            self.layer.cornerRadius = 12
            self.layer.masksToBounds = true
            self.layer.borderColor = UIColor.whiteColor().CGColor
            self.drawGrid(context)
            self.drawLine(context, pointsArray: dataPoints, lineColor: lineColor)
            drawNormalText(graphHeader, context:context, origin:CGPointMake(self.bounds.width/2.0, 15), x1:0.0, y1:0.0, align: .ctAlignCenterCenter, fontName:"Helvetica", fontSize:20.0, textColor:numeralColor)

        }
    }
    
    func processGradient(context: CGContextRef, startColor: UIColor, endColor: UIColor, gradient:CGGradientRef?) {
        if(gradient == nil) {
            let gradientColors: [AnyObject] = [startColor.CGColor, endColor.CGColor]
            let flocations: [CGFloat] = [ 0.0, 1.0 ]
            let rgbColorspace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradientCreateWithColors(rgbColorspace, gradientColors, flocations)
        }
        if let grad = gradient {
            CGContextDrawLinearGradient(context, grad, CGPointMake(self.bounds.size.width/2.0, 0), CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height),[])
        }
    }

    
    func drawGrid(context:CGContextRef) {
        switch yMax {
            case 0..<10:
                divSize = 0.5
                topSize = 10.0
            case 10..<20:
                divSize = 1.0
                topSize = 20.0
            case 20..<50:
                divSize = 2.5
                topSize = 50.0
            case 50..<100:
                divSize = 5.0
                topSize = 100
            case 100..<500:
                divSize = 25.0
                topSize = 500.0
            default:
                divSize = 50.0
                topSize = 1000.0
        }
        
        var scaledPoint:CGFloat = 0.0
        let path = CGPathCreateMutable()
        var delta:CGFloat = 0.0
        for y in 1..<21 {
            delta = divSize * CGFloat(y)
            scaledPoint = (CGFloat(self.bounds.size.height) / self.topSize) * delta
            CGPathMoveToPoint(path, nil, 0.0, floor(self.bounds.size.height - scaledPoint)+0.5)
            CGPathAddLineToPoint(path,nil,CGFloat(self.bounds.size.width-1),floor(self.bounds.size.height - scaledPoint)+0.5)
            let sx = String(format: "%02.1f",CGFloat(y) * self.divSize )
            drawNormalText(sx, context:context, origin:CGPointMake(4.0, floor(self.bounds.size.height - scaledPoint)+0.5), x1:0.0, y1:0.0, align: .ctAlignBottomLeft, fontName:"Helvetica", fontSize:10.0, textColor:numeralColor)
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
            scaledPoint = (CGFloat(self.bounds.size.height) / self.topSize) * CGFloat(startPoint)
        }
        CGPathMoveToPoint(path, nil, floor(x)+0.5, floor(self.bounds.size.height - scaledPoint)+0.5)
        let xDelta:CGFloat = CGFloat(self.bounds.size.width-1) / CGFloat(pointsArray.count)
        for point in pointsArray {
            if(point <= 0) {
                scaledPoint = 0.0
            }
            else {
                scaledPoint = (CGFloat(self.bounds.size.height) / self.topSize) * CGFloat(point)
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
    
    func measureLine(line: CTLineRef, context: CGContextRef) ->CGSize {
        var textHeight: CGFloat = 0.0
        var ascent:CGFloat = 0.0
        var descent:CGFloat = 0.0
        var leading:CGFloat = 0.0
        var width:Double = 0.0
        
        width = CTLineGetTypographicBounds(line, &ascent,  &descent, &leading)
        textHeight = floor(ascent * 0.8)
        return CGSizeMake(ceil(CGFloat(width)), ceil(textHeight))
    }
    
    func drawNormalText(text:String, context:CGContextRef, origin:CGPoint, x1:CGFloat, y1:CGFloat, align:textAlignTypes, fontName:String, fontSize:CGFloat, textColor:UIColor) {
        CGContextSaveGState(context)
        
        //let shadowColor = UIColor(red:0.151, green:0.152, blue:0.151, alpha:1.000)
        //CGContextSetShadowWithColor(context, CGSizeMake(1, 1), 0, shadowColor.CGColor)
        CGContextTranslateCTM(context, origin.x, origin.y) // move origin to center
        CGContextScaleCTM(context, 1.0, -1.0) // Reverse Y axis only
        
        // Create an attributed string
        let fontRef = CTFontCreateWithName(fontName, fontSize, nil)
        let attributes = [ NSFontAttributeName: fontRef, NSForegroundColorAttributeName: textColor ]
        let attString = NSAttributedString(string: text, attributes: attributes)
        
        // Create a text line from the attributed string
        let line:CTLineRef = CTLineCreateWithAttributedString(attString)
        let runArray = ((CTLineGetGlyphRuns(line) as [AnyObject]) as! [CTRunRef])
        let lineMetrics:CGSize = measureLine(line,context:context)
        for runIndex in 0..<CFArrayGetCount(runArray) {
            let run: CTRunRef = runArray[runIndex]
            var textMatrix:CGAffineTransform = CTRunGetTextMatrix(run)
            switch (align) {
            case .ctAlignTopLeft:
                textMatrix.tx = x1
                textMatrix.ty = y1 - lineMetrics.height
                
            case .ctAlignTopCenter:
                textMatrix.tx = x1 + (lineMetrics.width / 2.0)
                textMatrix.ty = y1 - lineMetrics.height
                
            case .ctAlignTopRight:
                textMatrix.tx = x1 + lineMetrics.width
                textMatrix.ty = y1 - lineMetrics.height
                
            case .ctAlignCenterLeft:
                textMatrix.tx = x1
                textMatrix.ty = y1 - (lineMetrics.height / 2.0)
                
            case .ctAlignCenterCenter:
                textMatrix.tx = x1 - (lineMetrics.width / 2.0)
                textMatrix.ty = y1 - (lineMetrics.height / 2.0)
                
            case .ctAlignCenterRight:
                textMatrix.tx = x1 - lineMetrics.width
                textMatrix.ty = y1 - (lineMetrics.height / 2.0)
                
            case .ctAlignBottomLeft:
                textMatrix.tx = x1
                textMatrix.ty = y1
                
            case .ctAlignBottomCenter:
                textMatrix.tx = x1 - (lineMetrics.width / 2.0)
                textMatrix.ty = y1
                
            case .ctAlignBottomRight:
                textMatrix.tx = x1 - lineMetrics.width
                textMatrix.ty = y1
                
            }
            CGContextSetTextMatrix(context, textMatrix)
            CTRunDraw(run, context, CFRangeMake(0, 0))
        }
        CGContextRestoreGState(context)
    }

}
