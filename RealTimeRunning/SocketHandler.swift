//
//  File.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 26/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import SocketIOClientSwift

struct SocketHandler {
    
    static let socket = SocketIOClient(socketURL: NSURL(string: "http://real-time-running.herokuapp.com")!)
    
}
