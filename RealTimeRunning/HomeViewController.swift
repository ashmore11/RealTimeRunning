//
//  ViewController.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 16/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Cloudinary
import MBProgressHUD
import Toucan

class HomeViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLUploaderDelegate {
    
    // MARK: Properties
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var topViewArea: UIView!
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var racesButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    let imagePicker = UIImagePickerController()
    let cloudinary = CLCloudinary(url: "cloudinary://634115678185717:yvgW6aX0JEje-J6j6uxOIsNMi1Y@scottashmore")
    var imageLoaderProgress: MBProgressHUD!
    var racesButtonPushed = false
    var racesReady = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if let id = NSUserDefaults.standardUserDefaults().objectForKey("userId") as? String {
            showActivityIndicator(self.view, text: nil)
            Users.sharedInstance.events.listenTo("collectionReady", action: {
                if let user = Users.sharedInstance.findOne(id) {
                    hideActivityIndicator(self.view)
                    CurrentUser.sharedInstance.setCurrentUser(user)
                    self.userLoggedIn()
                }
            })
        } else {
            self.performSegueWithIdentifier("showLogin", sender: self)
        }

        Races.sharedInstance.events.listenTo("collectionReady", action: { self.racesReady = true })
        
        setViewGradient(self.view)
        setButtonGradient(self.racesButton, self.logoutButton)
        
        self.imagePicker.delegate = self
        self.topViewArea.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.6)
        self.profileImage.layer.cornerRadius = 10
        self.profileImage.clipsToBounds = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.profileImageTapped))
        self.profileImage.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    @IBAction func racesButtonPushed(sender: UIButton) {
        
        if self.racesReady == true {
            self.performSegueWithIdentifier("showRaces", sender: sender)
        }
        
    }
    
    @IBAction func logoutButtonPushed(sender: UIButton) {
        
        NSUserDefaults.standardUserDefaults().removeObjectForKey("userId")
        self.performSegueWithIdentifier("showLogin", sender: nil)
        self.navigationItem.title = "REAL TIME RUNNING"
        CurrentUser.sharedInstance.loggedIn = false
        self.racesButton.enabled = false
        
    }
    
    @IBAction func unwindToHome(segue: UIStoryboardSegue) {
        
        self.userLoggedIn()
        
    }
    
    func userLoggedIn() {
        
        if let userName = CurrentUser.sharedInstance.username, let imageURL = CurrentUser.sharedInstance.imageURL, let rank = CurrentUser.sharedInstance.rank, points = CurrentUser.sharedInstance.points {
            self.navigationItem.title = userName.uppercaseString
            self.profileImage.image = imageFromString(imageURL)
            self.rankLabel.text = "\(rank)"
            self.pointsLabel.text = "\(points)"
        }
        
        Users.sharedInstance.events.listenTo("usersUpdated") {
            if let rank = CurrentUser.sharedInstance.rank, let points = CurrentUser.sharedInstance.points, let imageURL = CurrentUser.sharedInstance.imageURL {
                self.rankLabel.text = "\(rank)"
                self.pointsLabel.text = "\(points)"
                self.profileImage.image = imageFromString(imageURL)
            }
        }
        
        self.racesButton.enabled = true
        
        Races.sharedInstance.events.listenTo("collectionReady", action: {
        
            CurrentUser.sharedInstance.currentRaces?.forEach({ race in
                print(race.createdAt)
            })
            
        })
        
    }
    
    func profileImageTapped(img: AnyObject) {
        
        self.imagePicker.allowsEditing = false
        self.imagePicker.sourceType = .PhotoLibrary
        self.presentViewController(self.imagePicker, animated: true, completion: nil)
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            self.setupLoader()
            
            let resizedImage = Toucan(image: pickedImage).resize(CGSize(width: 130, height: 130), fitMode: Toucan.Resize.FitMode.Crop).image
            let forUpload = UIImagePNGRepresentation(resizedImage)! as NSData
            let uploader = CLUploader(self.cloudinary, delegate: self)
            
            if let id = CurrentUser.sharedInstance.id {
                uploader.upload(forUpload, options: ["public_id": id], withCompletion: onCloudinaryCompletion, andProgress: onCloudinaryProgress)
            }

        }
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func onCloudinaryCompletion(successResult: [NSObject : AnyObject]!, errorResult: String!, code: Int, idContext: AnyObject!) {
        
        if let url = successResult["url"] as? String, let id = CurrentUser.sharedInstance.id {
            dispatch_async(dispatch_get_main_queue()) {
                self.imageLoaderProgress.hide(true)
            }
            Users.sharedInstance.update(id, fields: [ "imageURL": url ])
        }
        
    }
    
    func onCloudinaryProgress(bytesWritten: Int, totalBytesWritten: Int, totalBytesExpectedToWrite: Int, idContext: AnyObject!) {
        
        let total = Double(totalBytesExpectedToWrite)
        let progress = Double(totalBytesWritten)
        let percent = progress / total
        
        dispatch_async(dispatch_get_main_queue()) {
            self.imageLoaderProgress.progress = Float(percent)
        }
        
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    
        self.dismissViewControllerAnimated(true, completion: nil)
    
    }
    
    func setupLoader() {
        
        dispatch_async(dispatch_get_main_queue()) {
            self.imageLoaderProgress = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            self.imageLoaderProgress.mode = .AnnularDeterminate
            self.imageLoaderProgress.dimBackground = true
            self.imageLoaderProgress.labelText = "Uploading Image"
            self.imageLoaderProgress.detailsLabelText = "Please wait..."
            self.imageLoaderProgress.labelFont = UIFont(name: "Oswald-Regular", size: 18)
            self.imageLoaderProgress.detailsLabelFont = UIFont(name: "Oswald-Regular", size: 14)
        }
        
    }
    
}

