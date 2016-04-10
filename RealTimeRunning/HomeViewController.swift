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
    
    var loginView: LoginViewController!
    var currentUser: CurrentUser = CurrentUser.sharedInstance
    var users: Users = Users.sharedInstance
    let races: Races = Races.sharedInstance
    var racesButtonPushed = false
    var racesReady = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.loginView = LoginViewController()
        
        if FBSDKAccessToken.currentAccessToken() === nil {
            self.performSegueWithIdentifier("showLogin", sender: nil)
        }
        
        self.loginView.events.listenTo("loginComplete", action: self.getData)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.usersSubscriptionReady), name: "usersSubscriptionReady", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.racesSubscriptionReady), name: "racesSubscriptionReady", object: nil)
        
        self.navigationItem.title = "REAL TIME RUNNING"
        
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
        
        self.loginView.logout()
        self.userLoggedOut()
        
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
    
    @IBAction func unwindToHome(segue: UIStoryboardSegue) {
        print("unwinding")
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
        
        self.performSegueWithIdentifier("showLogin", sender: nil)
        
        self.currentUser.loggedIn = false
        self.fbProfileImage.image = nil
        self.racesButton.enabled = false
        self.navigationItem.title = "REAL TIME RUNNING"
        
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
        
        self.loginView.performSegueWithIdentifier("unwindToHome", sender: self)
        
    }
    
    @IBAction func racesButtonPushed(sender: UIButton) {
        
        if self.racesReady == true {
            self.performSegueWithIdentifier("showRaces", sender: sender)
        }
        
    }
    
}

