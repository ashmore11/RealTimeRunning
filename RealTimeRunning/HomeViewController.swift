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
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var racesButton: UIButton!
    @IBOutlet weak var fbLoginButton: UIButton!
    
    let fbLoginManager: FBSDKLoginManager = FBSDKLoginManager()
    var currentUser: CurrentUser = CurrentUser.sharedInstance
    var users: Users = Users.sharedInstance
    let races: Races = Races.sharedInstance
    var racesButtonPushed = false
    var racesReady = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.usersSubscriptionReady), name: "usersSubscriptionReady", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.racesSubscriptionReady), name: "racesSubscriptionReady", object: nil)
        
        self.navigationItem.title = "REAL TIME RUNNING"
        self.topViewArea.alpha = 0
        
        self.setupLayout()
        
    }
    
    func usersSubscriptionReady(notification: NSNotification) {
        
        self.currentUser.sendRequest()
        self.currentUser.events.listenTo("userLoaded", action: {
            
            if let id = self.currentUser.id {
                if self.users.findOne(id) != nil {
                    let token = FBSDKAccessToken.currentAccessToken().tokenString
                    self.users.authenticateUser(token) {
                        self.userLoggedIn()
                    }
                } else {
                    self.fbLoginManager.logOut()
                }
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
        self.fbProfileImage.layer.cornerRadius = 10
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
    
    func getData() {
            
        self.currentUser.sendRequest()
        self.currentUser.events.listenTo("userLoaded", action: {
            if let id = self.currentUser.id, let name = self.currentUser.name, let email = self.currentUser.email, let imageURL = self.currentUser.imageURL {
                if self.users.findOne(id) != nil {
                    self.userLoggedIn()
                } else {
                    self.showUsernameAlert { username in
                        let parameters = [
                            "username": username,
                            "name": name,
                            "email": email,
                            "image": imageURL,
                            "points": 0
                        ]
                        self.users.insert(id, fields: parameters) {
                            self.userLoggedIn()
                        }
                    }
                }
            }
        })
        
    }
    
    func showUsernameAlert(completionHandler: (username: String) -> Void) {
        
        let alert = UsernameAlert()
        
        let title = "HELLO \(self.currentUser.name!.uppercaseString)!"
        let subTitle = "Create a username that is greater than 3 characters and less than 17. Username's must only contain letters and numbers."
        
        alert.showView(title, subTitleLabel: subTitle)
        
        alert.events.listenTo("buttonTapped", action: {
            if let username = alert.textField.text {
                if self.users.list.indexOf({ $0.username == username }) != nil {
                    alert.errorHappened("USERNAME ALREADY EXISTS")
                } else if username.characters.count < 4 {
                    alert.errorHappened("USERNAME TOO SHORT")
                } else {
                    completionHandler(username: username)
                    alert.hideView()
                }
            }
        })
        
    }
    
    func userLoggedOut() {
        
        UIView.animateWithDuration(0.25, delay: 0, options: [.CurveLinear], animations: { self.topViewArea.alpha = 0 }, completion: nil)
        
        self.currentUser.loggedIn = false
        self.fbProfileImage.image = nil
        self.racesButton.enabled = false
        self.navigationItem.title = "REAL TIME RUNNING"
        self.fbLoginButton.setTitle("SIGN IN", forState: .Normal)
        self.fadeRacesButton(0.5, delay: 0)
        
    }
    
    func userLoggedIn() {
        
        UIView.animateWithDuration(0.25, delay: 0, options: [.CurveLinear], animations: { self.topViewArea.alpha = 1 }, completion: nil)
        // ERROR optional username was nil fixed by Bob
        
        if let userName = self.currentUser.username {
            self.navigationItem.title = userName.uppercaseString
        }
        
        if let imageURL = self.currentUser.imageURL, let rank = self.currentUser.rank, points = self.currentUser.points {
            self.fbProfileImage.image = imageFromString(imageURL)
            self.rankLabel.text = "\(rank)"
            self.pointsLabel.text = "\(points)"
        }
        
        self.racesButton.enabled = true
        self.fbLoginButton.setTitle("SIGN OUT", forState: .Normal)
        self.fadeRacesButton(1, delay: 1)
        
        self.users.events.listenTo("usersUpdated") {
            if let rank = self.currentUser.rank, let points = self.currentUser.points {
                self.rankLabel.text = "\(rank)"
                self.pointsLabel.text = "\(points)"
            }
        }
        
    }
    
    @IBAction func racesButtonPushed(sender: UIButton) {
        
        if self.racesReady == true {
            self.performSegueWithIdentifier("showRaces", sender: sender)
        }
        
    }
    
}

