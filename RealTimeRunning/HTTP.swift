//
//  HTTP.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 23/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import Foundation
import Alamofire

class HTTP {
    
    init(fbid: String, name: String, email: String, profileImage: String) {
        
        let parameters = [
            "fbid": fbid,
            "name": name,
            "email": email,
            "profileImage": profileImage
        ]
    
        Alamofire.request(.POST, "http://localhost:3000/api/users", parameters: parameters, encoding: .JSON)
    
    }
    
}