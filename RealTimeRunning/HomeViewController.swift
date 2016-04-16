//
//  ViewController.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 16/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class HomeViewController: UIViewController {
    
    // MARK: Properties
    @IBOutlet weak var fbProfileImage: UIImageView!
    @IBOutlet weak var topViewArea: UIView!
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var racesButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
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
        
        self.setupLayout()
        
    }
    
    func usersSubscriptionReady(notification: NSNotification) {
        
        if let id = NSUserDefaults.standardUserDefaults().objectForKey("userId") as? String, let user = self.users.findOne(id) {
            self.currentUser.setCurrentUser(user)
            self.userLoggedIn()
        } else {
            self.performSegueWithIdentifier("showLogin", sender: nil)
        }
        
        self.currentUser.events.listenTo("userLoaded", action: {
            if let id = self.currentUser.id, let firstName = self.currentUser.firstName, let email = self.currentUser.email, let imageURL = self.currentUser.imageURL {
                if self.users.findOne(id) != nil {
                    self.userLoggedIn()
                } else {
                    self.showUsernameAlert { username in
                        let parameters = [
                            "username": username,
                            "firstName": firstName,
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
        
        let title = "HELLO \(self.currentUser.firstName!.uppercaseString)!"
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
    
    func racesSubscriptionReady(notification: NSNotification) {
        
        self.racesReady = true
        
    }
    
    func setupLayout() {
    
        setViewGradient(self.view)
        setButtonGradient(self.racesButton, self.logoutButton)
        
        self.topViewArea.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.6)
        self.fbProfileImage.layer.cornerRadius = 10
        self.fbProfileImage.clipsToBounds = true
        
    }
    
    @IBAction func logoutButtonPushed(sender: UIButton) {
        
        FBSDKLoginManager().logOut()
        self.userLoggedOut()
        
    }
    
    @IBAction func unwindToHome(segue: UIStoryboardSegue) {
//        print("unwinding from login screen")
    }
    
    func userLoggedOut() {
        
        NSUserDefaults.standardUserDefaults().removeObjectForKey("userId")
        
        self.performSegueWithIdentifier("showLogin", sender: nil)
        
        self.navigationItem.title = "REAL TIME RUNNING"
        self.currentUser.loggedIn = false
        self.fbProfileImage.image = nil
        self.racesButton.enabled = false
        
    }
    
    func userLoggedIn() {
        
        if let userName = self.currentUser.username, let imageURL = self.currentUser.imageURL, let rank = self.currentUser.rank, points = self.currentUser.points {
            self.navigationItem.title = userName.uppercaseString
            self.fbProfileImage.image = imageFromString(imageURL)
            self.rankLabel.text = "\(rank)"
            self.pointsLabel.text = "\(points)"
        }
        
        self.racesButton.enabled = true
        
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

