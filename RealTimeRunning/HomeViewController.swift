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

class raceTester {
    var start = NSDate() // <- Start time
    var runNumber = -1
    var testRaces:[Race] = []
    
    init(runNo:Int) {
        self.runNumber = runNo
    }
    
    func readRacesTest() ->[Race] {

        print("Executing readRacesTest for run \(self.runNumber)")
        let manager = Manager.sharedInstance
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        self.start = NSDate() // <- Start time
        manager.request(.GET, "http://real-time-running.herokuapp.com/api/races").responseSwiftyJSON({ (request, response, json, error) in
            let end = NSDate()   // <- End time
            if let err = error{
                print("Error:\(err)")
                return
            }
            for (_, value) in json {
                if let raceId = value["_id"].string, let createdAt = value["createdAt"].string, let parsedDate = formatter.dateFromString(createdAt), let competitors = value["competitors"].array, let distance = value["distance"].int, let live = value["live"].bool {
                    let race = Race(id: raceId, createdAt: parsedDate, competitors: competitors, distance: distance, live: live)
                    self.testRaces.append(race)
                }
            }
            let timeInterval: Double = end.timeIntervalSinceDate(self.start) // <- Difference in seconds (double)
            print("RunNumber: \(self.runNumber) Time to read races from server is: \(timeInterval) seconds Total Races: \(self.testRaces.count)")
            
        })
        return testRaces
    }
  
    
    
}

class HomeViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var fbProfileImage: UIImageView!
    @IBOutlet weak var topViewArea: UIView!
    @IBOutlet weak var racesButton: UIButton!
    
    var user: User?
    var races = [Race]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //testSeverRead()

        
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
    
        setViewGradient(self.view)
        
        topViewArea.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.6)
        
        setButtonGradient(racesButton)
        
        fbProfileImage.layer.cornerRadius = fbProfileImage.frame.size.width / 2
        fbProfileImage.clipsToBounds = true
        
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
        racesButton.enabled = false
        racesButton.alpha = 0
        
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
        
        let getURL = "http://real-time-running.herokuapp.com/api/users/\(fbid)"
        let postURL = "http://real-time-running.herokuapp.com/api/users/"
        
        Alamofire.request(.GET, getURL).responseSwiftyJSON({ (request, response, json, error) in
            
            if json.count == 0 {
                
                Alamofire.request(.POST, postURL, parameters: parameters, encoding: .JSON)
                    .responseSwiftyJSON({ (request, response, json, error) in
                    
                        print(json["message"])
                    
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
    
    func testSeverRead() {
        
        let totalReads = 100
        print("TEST RUN Started")
        for i in 0...totalReads {
            let newTester = raceTester(runNo: i)
            _ = newTester.readRacesTest()
        }
        print("TEST RUN Finished")
        
       
        
    }
    
    
    

}

