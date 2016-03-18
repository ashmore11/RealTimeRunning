//
//  UserData.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 18/03/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import EmitterKit

class UserData {
    
    static let sharedInstance = UserData()
    
    var id: String?
    var name: String?
    var email: String?
    var imageURL: String?
    var image: UIImage?
    var loaded = Signal()
    
    init() {
        
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            
            self.sendRequest()
        
        }
        
    }
        
    func sendRequest() {
        
        let accessToken = FBSDKAccessToken.currentAccessToken()
        let parameters = ["fields": "email, first_name, last_name, picture.type(large)"]
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: parameters, tokenString: accessToken.tokenString, version: nil, HTTPMethod: "GET")
        
        graphRequest.startWithCompletionHandler { (connection, result, error) -> Void in
            
            if error != nil {
                logError(error.localizedDescription)
                return
            }
            
            self.getData(result)
            
        }
        
    }
    
    func getData(data: AnyObject) {
        
        if let id = (data.objectForKey("id") as? String) {
        
            self.id = id
        
        }
        
        if let firstName = (data.objectForKey("first_name") as? String), lastName = (data.objectForKey("last_name") as? String) {
        
            self.name = firstName + " " + lastName
        
        }
        
        if let imageURL = (data.objectForKey("picture")?.objectForKey("data")?.objectForKey("url") as? String), let nsurl = NSURL(string: imageURL), let data = NSData(contentsOfURL:nsurl), let image = UIImage(data:data) {
            
            self.imageURL = imageURL
            
            self.image = image
            
        }
        
        if let email = (data.objectForKey("email") as? String) {
            
            self.email = email
            
        }
        
        self.loaded.emit()
        
    }
    
}