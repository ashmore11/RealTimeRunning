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
    @IBOutlet weak var emailLabel: UILabel!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            
            getData()
            
        }
        
        let loginButton = FBSDKLoginButton()
        
        loginButton.readPermissions = ["public_profile", "email", "user_friends"]
        loginButton.delegate = self
        
        let x = self.view.frame.size.width - (loginButton.frame.size.width + 20)
        let y = self.view.frame.size.height - loginButton.frame.size.height
        
        loginButton.center = CGPointMake(x, y)
        
        self.view.addSubview(loginButton)
        
    }
    
    // MARK: - Facebook Delegate Methods
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        if error == nil {
            
            getData()

        } else {
            
            print(error.localizedDescription)
            
        }
        
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        
        self.nameLabel.text = nil
        self.emailLabel.text = nil
        self.fbProfileImage.image = nil
        
    }
    
    // MARK: Display Data
    
    func getData() {
        
        let graphRequest = FBSDKGraphRequest.init(graphPath: "me", parameters: ["fields": "first_name, last_name, email, picture.type(large)"])
        
        graphRequest.startWithCompletionHandler { (connection, result, error) -> Void in
            
            let firstName: String = (result.objectForKey("first_name") as? String)!
            
            let lastName: String = (result.objectForKey("last_name") as? String)!
            
            let email: String = (result.objectForKey("email") as? String)!
            
            let imageURL: String = (result.objectForKey("picture")?.objectForKey("data")?.objectForKey("url") as? String)!
            
            let image: UIImage = UIImage(data: NSData(contentsOfURL: NSURL(string: imageURL)!)!)!
            
            self.nameLabel.text = "Name: \(firstName) \(lastName)"
            self.emailLabel.text = "Email: \(email)"
            self.fbProfileImage.image = image
            
        }
        
    }

}

