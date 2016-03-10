//
//  SocketIOManager.swift
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
        
        listenForEvents()
    
    }
    
    func establishConnection() {
    
        socket.connect()
        
        print("socket connected")
    
    }
    
    func closeConnection() {
    
        socket.disconnect()
        
        print("socket disconnected")
    
    }
    
    func raceUsersUpdated(index: Int, raceId: String, userId: String) {
        
        socket.emit("raceUpdated", index, raceId, userId)
        
    }
    
    func sendPositionUpdate(id: String, distance: Double, pace: Double) {
        
        socket.emit("positionUpdate", id, distance, pace)
        
    }
    
    private func listenForEvents() {
        
        socket.on("reloadCompetitors") { (data, ack) -> Void in
            
            let object = [
                "index": data[0],
                "raceId": data[1],
                "userId": data[2]
            ]
            
            self.postNotification("reloadCompetitors", object: object)
            
        }
        
        socket.on("positionUpdateReceived") { (data, ack) -> Void in
            
            let object = [
                "id": data[0],
                "distance": data[1],
                "speed": data[2]
            ]
            
            self.postNotification("positionUpdateReceived", object: object)
            
        }
        
    }
    
    func postNotification(name: String, object: [String: AnyObject]?) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(name, object: object)
        
    }
    
}
