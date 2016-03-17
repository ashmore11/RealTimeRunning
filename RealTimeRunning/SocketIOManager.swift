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
    
    }
    
    func establishConnection() {
    
        socket.connect()
        
        socket.on("connect") {data, ack in
            
            print("socket connected")
            
            self.listenForEvents()
        
        }
    
    }
    
    func closeConnection() {
    
        socket.disconnect()
        
        print("socket disconnected")
    
    }
    
    func updateCompetitors(userId: String, raceId: String) {
        
        socket.emit("updateCompetitors", userId, raceId)
        
    }
    
//    func raceUsersUpdated(raceId: String, userId: String) {
//        
//        socket.emit("raceUpdated", raceId, userId)
//        
//    }
    
    func sendPositionUpdate(id: String, distance: Double, pace: Double) {
        
        socket.emit("positionUpdate", id, distance, pace)
        
    }
    
    private func listenForEvents() {
        
        socket.on("competitorsUpdated") { (data, ack) -> Void in
            
            let object = [
                "raceId": data[0],
                "userId": data[1]
            ]
            
            self.postNotification("competitorsUpdated", object: object)
            
        }
        
        socket.on("positionUpdateReceived") { (data, ack) -> Void in
            
            let object = [
                "id": data[0],
                "distance": data[1],
                "pace": data[2]
            ]
            
            self.postNotification("positionUpdateReceived", object: object)
            
        }
        
    }
    
    func postNotification(name: String, object: [String: AnyObject]?) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(name, object: object)
        
    }
    
}
