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
    @IBOutlet weak var topViewArea: UIView!
    @IBOutlet weak var racesButton: UIButton!
    
    var user: User?
    
    let gradientLayer = CAGradientLayer()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupLayout()
        
        navigationItem.title = "SIGN IN"
        
        if let user = user {
            
            fbProfileImage.image = user.profileImage
            navigationItem.title = user.name
            
        }
        
        let loginButton: FBSDKLoginButton = FBSDKLoginButton()
        
        loginButton.readPermissions = ["public_profile", "email"]
        loginButton.delegate = self
        
        loginButton.center = self.view.center
        
        self.view.addSubview(loginButton)
        
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            
            getData()
            
        }
        
    }
    
    func setupLayout() {
        
        self.view.backgroundColor = UIColor.greenColor()
        
        gradientLayer.frame = self.view.bounds
        
        let color1 = UIColor.yellowColor().CGColor as CGColorRef
        let color2 = UIColor(red: 1.0, green: 0, blue: 0, alpha: 1.0).CGColor as CGColorRef
        
        gradientLayer.colors = [color1, color2]
        gradientLayer.locations = [0.0, 0.75]
        
        self.view.layer.insertSublayer(gradientLayer, atIndex: 0)
        
        topViewArea.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.5)
        
        racesButton.layer.shadowColor = UIColor.blackColor().CGColor
        racesButton.layer.shadowOffset = CGSizeMake(0, 0)
        racesButton.layer.shadowRadius = 5
        racesButton.layer.shadowOpacity = 0.5
        
        fbProfileImage.layer.cornerRadius = fbProfileImage.frame.size.width / 2
        fbProfileImage.clipsToBounds = true
        fbProfileImage.layer.borderWidth = 3
        fbProfileImage.layer.borderColor = UIColor.whiteColor().CGColor
        
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
        
        navigationItem.title = "SIGN IN"
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
            
            self.navigationItem.title = name
            
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

