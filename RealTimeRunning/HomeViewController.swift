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

class HomeViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var fbProfileImage: UIImageView!
    @IBOutlet weak var topViewArea: UIView!
    @IBOutlet weak var racesButton: UIButton!
    @IBOutlet weak var fbLoginButton: UIButton!
    
    @IBOutlet weak var userNameField: UITextField!
    var user: User?
    var races = [Race]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.addToolbarOnKeyboard(userNameField, action: "addedUserName", buttonText: "Add User")
        
        self.setupLayout()
        
        self.navigationItem.title = "REAL TIME RUNNING"
        
        if let user = user {
            
            self.fbProfileImage.image = user.profileImage
            
            navigationItem.title = user.name
            
        }
        
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            
            self.fbLoginButton.setTitle("SIGN OUT" , forState: .Normal)
            
            self.fadeRacesButton(1, delay: 0.25)
            
            self.getData()
            
        }
        
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
        
        let accessToken = FBSDKAccessToken.currentAccessToken()
        let parameters = ["fields": "email, first_name, last_name, picture.type(large)"]
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: parameters, tokenString: accessToken.tokenString, version: nil, HTTPMethod: "GET")
        
        graphRequest.startWithCompletionHandler { (connection, result, error) -> Void in
            
            if error != nil {
                logError(error.localizedDescription)
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
            
            self.navigationItem.title = name.uppercaseString
            
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
        
        let getURL = "http://real-time-running.herokuapp.com/api/users/\(fbid)"
        let postURL = "http://real-time-running.herokuapp.com/api/users/"
        
        Alamofire.request(.GET, getURL).responseSwiftyJSON({ (request, response, json, error) in
            
            if json.count == 0 {
                
                Alamofire.request(.POST, postURL, parameters: parameters, encoding: .JSON)
                    .responseSwiftyJSON({ (request, response, json, error) in
                    
                        print("Reply from Alamofire in createUser: \(json["message"])")
                    
                })
                
            }
            
        })
        
    }
    
    @IBAction func racesButtonPushed(sender: UIButton) {
        
        races = [Race]()
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        showActivityIndicator(self.view, text: "Loading Races")
        
        racesButton.enabled = false
        
        let requestURL = "http://real-time-running.herokuapp.com/api/races"
        
        Alamofire.request(.GET, requestURL).responseSwiftyJSON({ (request, response, json, error) in
                
            for (key, value) in json {
                
                if  let raceId = value["_id"].string,
                    let createdAt = value["createdAt"].string,
                    let parsedDate = formatter.dateFromString(createdAt),
                    let competitors = value["competitors"].arrayObject as? [String],
                    let distance = value["distance"].int,
                    let live = value["live"].bool {
                        
                        print(raceId, competitors)
                    
                        let race = Race(id: raceId, createdAt: parsedDate, competitors: competitors, distance: distance, live: live, index: Int(key)!)
                    
                        self.races.append(race)
                    
                }
                
            }
                    
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

