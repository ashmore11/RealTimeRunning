//
//  LoginViewController.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 10/04/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import TwitterKit
import DigitsKit

class LoginViewController: UIViewController {
    
    let fbLoginManager: FBSDKLoginManager = FBSDKLoginManager()

    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var twitterButton: UIButton!
    @IBOutlet weak var digitsButton: UIButton!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.view.frame = UIScreen.mainScreen().bounds

        setViewGradient(self.view)
        
        let cornerRadius = 5
        
        var rectShape = CAShapeLayer()
        rectShape.bounds = self.facebookButton.frame
        rectShape.position = self.facebookButton.center
        rectShape.path = UIBezierPath(roundedRect: self.facebookButton.bounds, byRoundingCorners: [.TopLeft, .TopRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).CGPath
        
        self.facebookButton.layer.mask = rectShape
        
        rectShape = CAShapeLayer()
        rectShape.bounds = self.digitsButton.frame
        rectShape.position = self.digitsButton.center
        rectShape.path = UIBezierPath(roundedRect: self.digitsButton.bounds, byRoundingCorners: [.BottomLeft, .BottomRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).CGPath
        
        self.digitsButton.layer.mask = rectShape
        
    }
    
    @IBAction func facebookButtonPushed(sender: UIButton) {
        
        self.fbLoginManager.logInWithReadPermissions(["public_profile", "email"], fromViewController: self, handler: { (result, error) in
            if error != nil {
                print("Error in fbLoginManager.logInWithReadPermissionserror:\(error)")
                return
            }
            let fbloginresult: FBSDKLoginManagerLoginResult = result
            if(fbloginresult.grantedPermissions.contains("email")) {
                let token = FBSDKAccessToken.currentAccessToken().tokenString
                Users.sharedInstance.authenticateUser(token) {
                    CurrentUser.sharedInstance.sendRequest()
                    self.performSegueWithIdentifier("unwindToHome", sender: self)
                }
            }
        })
    
    }
    
    @IBAction func twitterButtonPushed(sender: UIButton) {
        
        Twitter.sharedInstance().logInWithCompletion { session, error in
            if (session != nil) {
                print("signed in as \(session?.userName)");
            } else {
                print("error: \(error?.localizedDescription)");
            }
        }
//        self.performSegueWithIdentifier("unwindToHome", sender: self)
    
    }
    
    @IBAction func digitsButtonPushed(sender: UIButton) {
        
        let digits = Digits.sharedInstance()
        digits.authenticateWithCompletion { (session, error) in
            if (session != nil) {
                print("signed in as \(session.phoneNumber)");
            } else {
                print("error: \(error?.localizedDescription)");
            }
        }
        
    }
    
    func logout() {
        
        self.fbLoginManager.logOut()
        
    }


}
