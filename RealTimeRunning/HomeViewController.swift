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
import Alamofire
import SwiftyJSON
import Alamofire_SwiftyJSON
import MBProgressHUD
import SwiftDDP

class HomeViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var fbProfileImage: UIImageView!
    @IBOutlet weak var topViewArea: UIView!
    @IBOutlet weak var racesButton: UIButton!
    @IBOutlet weak var fbLoginButton: UIButton!
    @IBOutlet weak var userNameField: UITextField!
    
    let users: MeteorCollection<User> = (UIApplication.sharedApplication().delegate as! AppDelegate).users
    var racesButtonPushed = false
    var racesReady = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "racesSubscriptionReady:", name: "racesSubscriptionReady", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "usersSubscriptionReady:", name: "usersSubscriptionReady", object: nil)
        
        self.addToolbarOnKeyboard(userNameField, action: "addedUserName", buttonText: "Add User")
        
        self.setupLayout()
        
        self.navigationItem.title = "REAL TIME RUNNING"
        
    }
    
    func usersSubscriptionReady(notification: NSNotification) {
        
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            
            self.fbLoginButton.setTitle("SIGN OUT" , forState: .Normal)
            
            self.fadeRacesButton(1, delay: 0.25)
            
            self.getData()
            
        }
        
    }
    
    func racesSubscriptionReady(notification: NSNotification) {
        
        self.racesReady = true
        
    }
    
    func addedUserName() {
        
        self.userNameField.resignFirstResponder()
        
        if let userName = self.userNameField.text {
            print("Added a username \(userName)")
        }
        
    }
    
    func setupLayout() {
    
        setViewGradient(self.view)
        
        self.topViewArea.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.6)
        
        setButtonGradient(self.racesButton, self.fbLoginButton)
        self.racesButton.alpha = 0.5
        
        self.fbProfileImage.layer.cornerRadius = fbProfileImage.frame.size.width / 2
        self.fbProfileImage.clipsToBounds = true
        
    }
    
    func fadeRacesButton(alpha: CGFloat, delay: NSTimeInterval) {
        
        UIView.animateWithDuration(0.3, delay: delay, options: [.CurveEaseInOut], animations: { self.racesButton.alpha = alpha }, completion: nil)
        
    }
    
    // MARK: - Facebook Delegate Methods
    
    @IBAction func fbLoginButtonPushed(sender: UIButton) {
    
        let fbLoginManager: FBSDKLoginManager = FBSDKLoginManager()
        
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            
            fbLoginManager.logOut()
            
            self.userLoggedOut()
            
        } else {
            
            fbLoginManager.logInWithReadPermissions(["public_profile", "email"], fromViewController: self, handler: { (result, error) -> Void in
                
                if error != nil {
                    print("Error in fbLoginManager.logInWithReadPermissionserror:\(error)")
                    return
                }
                
                let fbloginresult: FBSDKLoginManagerLoginResult = result
                
                if(fbloginresult.grantedPermissions.contains("email")) {
                    
                    UserData.sharedInstance.sendRequest()
                    
                    self.userLoggedIn()
                    
                }
            })
        }
        
    }
    
    func userLoggedOut() {
        
        self.fbLoginButton.setTitle("SIGN IN" , forState: .Normal)
        self.navigationItem.title = "REAL TIME RUNNING"
        self.fbProfileImage.image = nil
        self.racesButton.enabled = false
        self.fadeRacesButton(0.5, delay: 0)
        
    }
    
    func userLoggedIn() {
            
        self.getData()
        self.fbLoginButton.setTitle("SIGN OUT" , forState: .Normal)
        self.racesButton.enabled = true
        self.fadeRacesButton(1, delay: 1)
        
    }
    
    func getData() {
        
        let data = UserData.sharedInstance
        
        data.loaded.once {
        
            if let id = data.id, let name = data.name, let email = data.email, let imageURL = data.imageURL, let image = data.image {
                
                self.navigationItem.title = name.uppercaseString
                self.fbProfileImage.image = image
                
                self.createUser(id, name: name, email: email, imageURL: imageURL)
                
            }
            
        }
        
    }
    
    func createUser(id: String, name: String, email: String, imageURL: String) {
        
        if users.findOne(id) == nil {
        
            let parameters = [
                "name": name,
                "email": email,
                "image": imageURL
            ]
            
            let user = User(id: id, fields: parameters)
            
            users.insert(user)
        
        }
        
    }
    
    @IBAction func racesButtonPushed(sender: UIButton) {
        
        self.performSegueWithIdentifier("showRaces", sender: sender)
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showRaces" {
            
            racesButton.enabled = true
            
        }
        
    }
    
    func addToolbarOnKeyboard(view: UIView?, action:Selector, buttonText:String) {
        
        let toolbar: UIToolbar = UIToolbar(frame: CGRectMake(0, 0, 320, 50))
        toolbar.barStyle = UIBarStyle.BlackTranslucent
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: buttonText, style: UIBarButtonItemStyle.Plain, target: self, action: action)
        let cancel: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: view, action:  "resignFirstResponder")
        
        toolbar.items = [flexSpace,cancel,done]
        toolbar.sizeToFit()
        
        if let accessorizedView = view as? UITextView {
            accessorizedView.inputAccessoryView = toolbar
            accessorizedView.inputAccessoryView = toolbar
        } else if let accessorizedView = view as? UITextField {
            accessorizedView.inputAccessoryView = toolbar
            accessorizedView.inputAccessoryView = toolbar
        }
        
    }
    
}

