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

class HomeViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var fbProfileImage: UIImageView!
    @IBOutlet weak var topViewArea: UIView!
    @IBOutlet weak var racesButton: UIButton!
    
    var user: User?
    var races = [Race]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        SocketHandler.socket.connect()
        
        SocketHandler.socket.on("connect") {data, ack in
            
            print("socket connected")
            
        }
        
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
        loginButton.frame.origin.y = topViewArea.frame.size.height + loginButton.frame.size.height + 50
        
        self.view.addSubview(loginButton)
        
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            
            getData()
            
        }
        
    }
    
    func setupLayout() {
        
        let gradientLayer = CAGradientLayer()
        
        gradientLayer.frame = self.view.bounds
        
        let color1 = UIColor(red: 0.878, green: 0.517, blue: 0.258, alpha: 1.0).CGColor as CGColorRef
        let color2 = UIColor(red: 0.592, green: 0.172, blue: 0.070, alpha: 1.0).CGColor as CGColorRef
        
        gradientLayer.colors = [color1, color2]
        gradientLayer.locations = [0.0, 0.75]
        
        self.view.layer.insertSublayer(gradientLayer, atIndex: 0)
        
        topViewArea.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.6)
        
        racesButton.layer.shadowColor = UIColor.blackColor().CGColor
        racesButton.layer.shadowOffset = CGSizeMake(0, 0)
        racesButton.layer.shadowRadius = 5
        racesButton.layer.shadowOpacity = 0.5
        
        fbProfileImage.layer.cornerRadius = fbProfileImage.frame.size.width / 2
        fbProfileImage.clipsToBounds = true
        
        racesButton.backgroundColor = UIColor.blackColor()
        
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
            var profileImageURL: String = ""
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
                let directoryURL: NSURL = nsurl
                let urlString: String = directoryURL.absoluteString
                
                profileImageURL = urlString
                profileImage = image
            }
            
            self.fbProfileImage.image = profileImage
            
            if let fbEmail: String = (result.objectForKey("email") as? String) {
                email = fbEmail
            }
            
            self.user = User(id: id, profileImage: profileImage, name: name, email: email)
            
            self.createUser(id, name: name, email: email, profileImageURL: profileImageURL)
            
        }
        
    }
    
    func createUser(fbid: String, name: String, email: String, profileImageURL: String) {
        
        let parameters = [
            "fbid": fbid,
            "name": name,
            "email": email,
            "profileImage": profileImageURL
        ]
        
        Alamofire.request(.GET, "http://real-time-running.herokuapp.com/api/users/\(fbid)").responseSwiftyJSON({ (request, response, json, error) in
            
            if json.count == 0 {
                
                Alamofire.request(.POST, "http://real-time-running.herokuapp.com/api/users/", parameters: parameters, encoding: .JSON).responseSwiftyJSON({ (request, response, json, error) in
                    
                    print(json["message"])
                    
                })
                
            } else {
                
                print("user found:", self.user!.name)
                
            }
            
        })
        
    }
    
    @IBAction func racesButtonPushed(sender: UIButton) {
        
        races = [Race]()
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        showActivityIndicator(self.view, text: "Loading Races")
        
        racesButton.enabled = false
        
        Alamofire.request(.GET, "http://real-time-running.herokuapp.com/api/races").responseSwiftyJSON({ (request, response, json, error) in
                
            json.forEach({ (index, value) in
                
                if let raceId = value["_id"].string, let createdAt = value["createdAt"].string, let parsedDate = formatter.dateFromString(createdAt), let competitors = value["competitors"].array, let distance = value["distance"].int, let live = value["live"].bool {
                    
                    let race = Race(id: raceId, createdAt: parsedDate, competitors: competitors, distance: distance, live: live, index: Int(index)!)
                    
                    self.races.append(race)
                    
                }
                
            })
                    
            hideActivityIndicator(self.view)
                    
            self.performSegueWithIdentifier("showRaces", sender: sender)
            
        })
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showRaces" {
            
            racesButton.enabled = true
            
            let backItem = UIBarButtonItem()
            backItem.title = "PROFILE"
            navigationItem.backBarButtonItem = backItem
            
            if let controller = segue.destinationViewController as? RacesTableViewController {
                
                controller.user = self.user
                controller.races = self.races
                
            }
            
        }
        
    }

}

