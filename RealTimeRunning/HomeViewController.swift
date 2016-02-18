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
    
    // MARK: Properties
    
    @IBOutlet weak var fbProfileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    var user: User?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.nameLabel.text = nil
        
        if let user = user {
            
            fbProfileImage.image = user.profileImage
            nameLabel.text = user.name
            
        }
        
        let loginButton: FBSDKLoginButton = FBSDKLoginButton()
        
        loginButton.readPermissions = ["public_profile", "email"]
        loginButton.delegate = self
        
        let x = self.view.frame.size.width - (loginButton.frame.size.width + 20)
        let y = self.view.frame.size.height - loginButton.frame.size.height
        
        loginButton.center = CGPointMake(x, y)
        
        self.view.addSubview(loginButton)
        
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            
            getData()
            
        }
        
    }
    
    // MARK: - Facebook Delegate Methods
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        if error == nil {
            
            print("Login complete.")
            
            getData()

        } else {
            
            print(error.localizedDescription)
            
        }
        
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        
        print("User logged out...")
        
        self.nameLabel.text = "Not Logged in"
        self.fbProfileImage.image = nil
        
    }
    
    func getData() {
        
        let accessToken = FBSDKAccessToken.currentAccessToken()
        let parameters = ["fields": "email, first_name, last_name, picture.type(large)"]
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: parameters, tokenString: accessToken.tokenString, version: nil, HTTPMethod: "GET")
        
        graphRequest.startWithCompletionHandler { (connection, result, error) -> Void in
            
            if error != nil {
                print(error.localizedDescription)
                return
            }
            
            // Get the facebook data and deal with optionals
            var id: String = ""
            var profileImage: UIImage?
            var name: String = ""
            var email: String = ""
            
            if let fbid: String = (result.objectForKey("id") as? String) {
                id = fbid
            }
            
            if let firstName: String = (result.objectForKey("first_name") as? String), lastName: String = (result.objectForKey("last_name") as? String) {
                name = firstName + " " + lastName
            }
            
            self.nameLabel.text = String(format: "Logged in as: %@", name)
            
            // if all optionals unwrap OK then we can setup the image
            if let imageURL: String = (result.objectForKey("picture")?.objectForKey("data")?.objectForKey("url") as? String), let nsurl = NSURL(string: imageURL), let data = NSData(contentsOfURL:nsurl), let image = UIImage(data:data) {
                profileImage = image
            }
            
            self.fbProfileImage.image = profileImage
            
            if let fbEmail: String = (result.objectForKey("email") as? String) {
                email = fbEmail
            }
            
            self.user = User(id: id, profileImage: profileImage, name: name, email: email)
            
        }
        
    }

}

