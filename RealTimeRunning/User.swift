//
//  User.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 18/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

class User {
    
    var id: String
    var profileImage: UIImage?
    var name: String
    var email: String
    
    init?(id: String, profileImage: UIImage?, name: String, email: String) {
        
        self.id = id
        self.profileImage = profileImage
        self.name = name
        self.email = email
        
        if id.isEmpty || name.isEmpty {
            
            return nil
            
        }
        
    }
    
}
