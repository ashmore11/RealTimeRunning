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
import SwiftDDP

class HomeViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var fbProfileImage: UIImageView!
    @IBOutlet weak var topViewArea: UIView!
    @IBOutlet weak var racesButton: UIButton!
    @IBOutlet weak var fbLoginButton: UIButton!
    @IBOutlet weak var userNameField: UITextField!
    
    let currentUser = CurrentUser.sharedInstance
    let users: Users = (UIApplication.sharedApplication().delegate as! AppDelegate).users
    let races: Races = (UIApplication.sharedApplication().delegate as! AppDelegate).races
    var racesButtonPushed = false
    var racesReady = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "racesSubscriptionReady:", name: "racesSubscriptionReady", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "usersSubscriptionReady:", name: "usersSubscriptionReady", object: nil)
        
        self.navigationItem.title = "REAL TIME RUNNING"
        
        self.addToolbarOnKeyboard(userNameField, action: "addedUserName", buttonText: "Add User")
        
        self.setupLayout()
        
    }
    
    func usersSubscriptionReady(notification: NSNotification) {
        
        self.currentUser.sendRequest()
        self.currentUser.events.listenTo("userLoaded", action: {
            
            if let id = self.currentUser.id {
                
                if self.users.findOne(id) != nil {
                    
                    let token = FBSDKAccessToken.currentAccessToken().tokenString
                    
                    self.users.authenticateUser(token)
                    
                    self.userLoggedIn()
                
                }
                
            }
        
        })
        
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
        setButtonGradient(self.racesButton, self.fbLoginButton)
        
        self.topViewArea.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.6)
        self.fbProfileImage.layer.cornerRadius = fbProfileImage.frame.size.width / 2
        self.fbProfileImage.clipsToBounds = true
        self.racesButton.alpha = 0.5
        
    }
    
    func fadeRacesButton(alpha: CGFloat, delay: NSTimeInterval) {
        
        UIView.animateWithDuration(0.3, delay: delay, options: [.CurveEaseInOut], animations: { self.racesButton.alpha = alpha }, completion: nil)
        
    }
    
    // MARK: - Facebook Delegate Methods
    
    @IBAction func fbLoginButtonPushed(sender: UIButton) {
    
        let fbLoginManager: FBSDKLoginManager = FBSDKLoginManager()
        
        if self.currentUser.loggedIn == true {
            
            fbLoginManager.logOut()
            
            self.userLoggedOut()
            
        } else {
            
            fbLoginManager.logInWithReadPermissions(["public_profile", "email"], fromViewController: self, handler: { (result, error) in
                
                if error != nil {
                    print("Error in fbLoginManager.logInWithReadPermissionserror:\(error)")
                    return
                }
                
                let fbloginresult: FBSDKLoginManagerLoginResult = result
                
                if(fbloginresult.grantedPermissions.contains("email")) {
                    
                    self.getData()
                    
                }
                
            })
            
        }
        
    }
    
    func getData() {
        
        self.currentUser.sendRequest()
        self.currentUser.events.listenTo("userLoaded", action: {
            
            self.users.authenticateUser(FBSDKAccessToken.currentAccessToken().tokenString)
            
            if let id = self.currentUser.id, let name = self.currentUser.name, let email = self.currentUser.email, let imageURL = self.currentUser.imageURL {
                
                if self.users.findOne(id) == nil {
                
                    self.createUser(id, name: name, email: email, imageURL: imageURL)
                    
                } else {
                    
                    self.userLoggedIn()
                    
                }
                
            }
            
        })
        
    }
    
    func createUser(id: String, name: String, email: String, imageURL: String) {
            
        let parameters = [
            "name": name,
            "email": email,
            "image": imageURL
        ]
        
        users.insert(id, fields: parameters) { user in
            
            self.userLoggedIn()
            
        }
        
    }
    
    func userLoggedOut() {
        
        self.navigationItem.title = "REAL TIME RUNNING"
        self.fbProfileImage.image = nil
        self.fbLoginButton.setTitle("SIGN IN" , forState: .Normal)
        self.racesButton.enabled = false
        self.fadeRacesButton(0.5, delay: 0)
        self.currentUser.loggedIn = false
        
    }
    
    func userLoggedIn() {
        
        self.navigationItem.title = self.currentUser.name!.uppercaseString
        self.fbProfileImage.image = self.currentUser.image
        self.fbLoginButton.setTitle("SIGN OUT" , forState: .Normal)
        self.racesButton.enabled = true
        self.fadeRacesButton(1, delay: 1)
        
    }
    
    @IBAction func racesButtonPushed(sender: UIButton) {
        
        if self.racesReady == true {
         
            self.performSegueWithIdentifier("showRaces", sender: sender)
            
        }
        
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

