//
//  File.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 26/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import SocketIOClientSwift

class SocketIOManager: NSObject {
    
    static let sharedInstance = SocketIOManager()
    
    var socket = SocketIOClient(socketURL: NSURL(string: "http://real-time-running.herokuapp.com")!)
    
    override init() {
    
        super.init()
    
    }
    
    func establishConnection() {
    
        socket.connect()
        
        print("socket connected")
    
    }
    
    func closeConnection() {
    
        socket.disconnect()
        
        print("socket disconnected")
    
    }
    
    func raceUsersUpdated(index: Int, id: String) {
        
        socket.emit("raceUpdated", index, id)
        
    }
    
    func reloadRaceCell(completionHandler: (index: Int, id: String) -> Void) {
        
        socket.on("reloadRaceView") { (data, ack) -> Void in
            
            completionHandler(index: data[0] as! Int, id: data[1] as! String)
            
        }
        
    }
    
    func sendPositionUpdate(id: String, distance: Double, speed: Double) {
        
        socket.emit("positionUpdate", id, distance, speed)
        
    }
    
    func getPositionUpdate(completionHandler: (id: String, distance: Double, speed: Double) -> Void) {
        
        socket.on("positionUpdateReceived") { (data, ack) -> Void in
            
            completionHandler(id: data[0] as! String, distance: data[1] as! Double, speed: data[2] as! Double)
            
        }
        
    }
    
}
