//
//  utilityFunctions.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 25/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import Foundation

func stringFromTimeInterval(interval:NSTimeInterval) -> String {
    let ti = NSInteger(interval)
    let seconds = ti % 60
    let minutes = (ti / 60) % 60
    let hours = (ti / 3600)
    return String(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
}
