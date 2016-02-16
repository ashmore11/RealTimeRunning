//
//  ViewController.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 16/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class HomeViewController: UIViewController, FBSDKLoginButtonDelegate {

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if (FBSDKAccessToken.currentAccessToken() == nil) {
            
            print("Not logged in...")
            
        } else {
            
            print("Logged in...")
            
        }
        
        let loginButton = FBSDKLoginButton()
        
        loginButton.readPermissions = ["public_profile", "email", "user_friends"]
        loginButton.center = self.view.center
        loginButton.delegate = self
        
        self.view.addSubview(loginButton)
        
    }
    
    // MARK: - Facebook Delegate Methods
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        if error == nil {
            
            print("Login complete.")
        
            self.performSegueWithIdentifier("showNew", sender: self)

        } else {
            
            print(error.localizedDescription)
        }
        
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        
        print("User logged out...")
        
    }



}

