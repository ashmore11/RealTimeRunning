//
//  File.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 26/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import SocketIOClientSwift

struct SocketHandler {
    
    static let socket = SocketIOClient(socketURL: NSURL(string: "http://192.168.168.108:3000")!)
    
}
