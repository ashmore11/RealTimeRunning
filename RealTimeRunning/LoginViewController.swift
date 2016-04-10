//
//  LoginViewController.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 10/04/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class LoginViewController: UIViewController {
    
    let fbLoginManager: FBSDKLoginManager = FBSDKLoginManager()
    let events: EventManager = EventManager()
    
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var twitterButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.view.frame = UIScreen.mainScreen().bounds

        setViewGradient(self.view)
        
        let cornerRadius = 5
        
        var rectShape = CAShapeLayer()
        rectShape.bounds = self.emailTextField.frame
        rectShape.position = self.emailTextField.center
        rectShape.path = UIBezierPath(roundedRect: self.emailTextField.bounds, byRoundingCorners: [.TopLeft, .TopRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).CGPath
        
        self.emailTextField.borderStyle = .None
        self.emailTextField.layer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.8).CGColor
        self.emailTextField.layer.mask = rectShape
        
        self.passwordTextField.borderStyle = .None
        self.passwordTextField.layer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.8).CGColor
        
        rectShape = CAShapeLayer()
        rectShape.bounds = self.signInButton.frame
        rectShape.position = self.signInButton.center
        rectShape.path = UIBezierPath(roundedRect: self.signInButton.bounds, byRoundingCorners: [.BottomLeft, .BottomRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).CGPath
        
        self.signInButton.layer.mask = rectShape
        self.signInButton.enabled = false
        self.signInButton.alpha = 0.3
        
        rectShape = CAShapeLayer()
        rectShape.bounds = self.facebookButton.frame
        rectShape.position = self.facebookButton.center
        rectShape.path = UIBezierPath(roundedRect: self.facebookButton.bounds, byRoundingCorners: [.TopLeft, .TopRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).CGPath
        
        self.facebookButton.layer.mask = rectShape
        
        rectShape = CAShapeLayer()
        rectShape.bounds = self.twitterButton.frame
        rectShape.position = self.twitterButton.center
        rectShape.path = UIBezierPath(roundedRect: self.twitterButton.bounds, byRoundingCorners: [.BottomLeft, .BottomRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).CGPath
    
        self.twitterButton.layer.mask = rectShape
        
    }
    
    @IBAction func SignInButtonPushed(sender: UIButton) {
        
        self.events.trigger("signInButtonPushed")
        
    }
    
    @IBAction func facebookButtonPushed(sender: UIButton) {
        
        self.fbLoginManager.logInWithReadPermissions(["public_profile", "email"], fromViewController: self, handler: { (result, error) in
            if error != nil {
                print("Error in fbLoginManager.logInWithReadPermissionserror:\(error)")
                self.events.trigger("loginFailed")
                return
            }
            let fbloginresult: FBSDKLoginManagerLoginResult = result
            if(fbloginresult.grantedPermissions.contains("email")) {
                let token = FBSDKAccessToken.currentAccessToken().tokenString
                Users.sharedInstance.authenticateUser(token) {
                    self.events.trigger("loginComplete")
                }
            }
        })
    
    }
    
    @IBAction func twitterButtonPushed(sender: UIButton) {
        
        self.events.trigger("twitterButtonPushed")
    
    }
    
    func logout() {
        
        self.fbLoginManager.logOut()
        
    }
    
    func show(duration: Double) {
        
        let window = UIApplication.sharedApplication().keyWindow! as UIWindow
        window.bringSubviewToFront(self.view)
        
        UIView.animateWithDuration(duration, animations: { self.view.alpha = 1 }, completion: nil)
        
    }
    
    func hide() {
        
        let window = UIApplication.sharedApplication().keyWindow! as UIWindow
        
        UIView.animateWithDuration(0.2, animations: { self.view.alpha = 0 }, completion: { finished in
            window.sendSubviewToBack(self.view)
        })
        
    }


}
