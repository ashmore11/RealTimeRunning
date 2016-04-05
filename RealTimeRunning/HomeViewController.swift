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

class HomeViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var fbProfileImage: UIImageView!
    @IBOutlet weak var topViewArea: UIView!
    @IBOutlet weak var racesButton: UIButton!
    @IBOutlet weak var fbLoginButton: UIButton!
    
    let fbLoginManager: FBSDKLoginManager = FBSDKLoginManager()
    let currentUser = CurrentUser.sharedInstance
    let users: Users = (UIApplication.sharedApplication().delegate as! AppDelegate).users
    let races: Races = (UIApplication.sharedApplication().delegate as! AppDelegate).races
    var racesButtonPushed = false
    var racesReady = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.racesSubscriptionReady), name: "racesSubscriptionReady", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.usersSubscriptionReady), name: "usersSubscriptionReady", object: nil)
        
        self.navigationItem.title = "REAL TIME RUNNING"
        
        self.topViewArea.alpha = 0
        
        self.setupLayout()
        
    }
    
    func usersSubscriptionReady(notification: NSNotification) {
        
        self.currentUser.sendRequest()
        self.currentUser.events.listenTo("userLoaded", action: {
            
            if let id = self.currentUser.id, let user = self.users.findOne(id) {
                    
                self.currentUser.username = user.username
                
                let token = FBSDKAccessToken.currentAccessToken().tokenString
                
                self.users.authenticateUser(token) {
                
                    self.userLoggedIn()
                
                }
            
            } else {
                    
                self.fbLoginManager.logOut()
                
            }
        
        })
        
    }
    
    func racesSubscriptionReady(notification: NSNotification) {
        
        self.racesReady = true
        
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
    
    @IBAction func fbLoginButtonPushed(sender: UIButton) {
        
        if self.currentUser.loggedIn == true {
            
            self.fbLoginManager.logOut()
            
            self.userLoggedOut()
            
        } else {
            
            self.fbLoginManager.logInWithReadPermissions(["public_profile", "email"], fromViewController: self, handler: { (result, error) in
                
                if error != nil {
                    print("Error in fbLoginManager.logInWithReadPermissionserror:\(error)")
                    return
                }
                
                let fbloginresult: FBSDKLoginManagerLoginResult = result
                
                if(fbloginresult.grantedPermissions.contains("email")) {
                    
                    let token = FBSDKAccessToken.currentAccessToken().tokenString
                    
                    self.users.authenticateUser(token) {
                     
                        self.getData()
                        
                    }
                    
                }
                
            })
            
        }
        
    }
    
    func showUsernameAlert(completionHandler: (username: String) -> Void) {
        
        let alert = SCLAlertView()
        alert.showCloseButton = false
        
        let textField = alert.addTextField("USERNAME")
        
        textField.delegate = self
        
        textField.textAlignment = .Center
        textField.autocapitalizationType = UITextAutocapitalizationType.AllCharacters
        
        alert.addButton("CREATE") {
            
            if let username = textField.text {
                
                if self.users.list.indexOf({ $0.username == username }) != nil || username.characters.count < 4 {
                    
                    alert.errorHappened("USERNAME ALREADY EXISTS")
                
                } else {
                    
                    completionHandler(username: username)
                    
                    alert.hideView()
                    
                }
                
            }
            
        }
        
        let title = "CREATE YOUR USERNAME"
        let subTitle = "Create a username that is greater than 4 characters and less than 16. Username's must only contain letters and numbers."
        
        alert.show(title, subTitle: subTitle)
        
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        
        let newLength = text.characters.count + string.characters.count - range.length
        
        return newLength <= 16
        
    }
    
    func getData() {
            
        self.currentUser.sendRequest()
        self.currentUser.events.listenTo("userLoaded", action: {
                
            if let id = self.currentUser.id, let name = self.currentUser.name, let email = self.currentUser.email, let imageURL = self.currentUser.imageURL {
                
                if self.users.findOne(id) != nil {
                    
                    self.userLoggedIn()
                    
                } else {
                    
                    self.showUsernameAlert { username in
                        
                        self.currentUser.username = username
                        
                        let parameters = [
                            "username": username,
                            "name": name,
                            "email": email,
                            "image": imageURL
                        ]
                        
                        self.users.insert(id, fields: parameters) {
                            
                            self.userLoggedIn()
                            
                        }
                    
                    }
                    
                }
                
            }
            
        })
        
    }
    
    func userLoggedOut() {
        
        UIView.animateWithDuration(0.25, delay: 0, options: [.CurveLinear], animations: { self.topViewArea.alpha = 0 }, completion: nil)
        
        self.navigationItem.title = "REAL TIME RUNNING"
        self.fbProfileImage.image = nil
        self.fbLoginButton.setTitle("SIGN IN" , forState: .Normal)
        self.racesButton.enabled = false
        self.fadeRacesButton(0.5, delay: 0)
        self.currentUser.loggedIn = false
        
    }
    
    func userLoggedIn() {
        
        UIView.animateWithDuration(0.25, delay: 0, options: [.CurveLinear], animations: { self.topViewArea.alpha = 1 }, completion: nil)
        
        self.navigationItem.title = self.currentUser.username!.uppercaseString
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
    
}

