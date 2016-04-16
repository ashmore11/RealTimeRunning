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

    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.view.frame = UIScreen.mainScreen().bounds

        setViewGradient(self.view)
        
        let cornerRadius: CGFloat = 5
        
        var rectShape = CAShapeLayer()
        rectShape.bounds = self.emailTextField.frame
        rectShape.position = self.emailTextField.center
        rectShape.path = UIBezierPath(roundedRect: self.emailTextField.bounds, byRoundingCorners: [.TopLeft, .TopRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).CGPath
        
        self.emailTextField.borderStyle = .None
        self.emailTextField.layer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.8).CGColor
        self.emailTextField.layer.mask = rectShape
        self.emailTextField.alpha = 0.8
        
        self.passwordTextField.borderStyle = .None
        self.passwordTextField.layer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.8).CGColor
        self.passwordTextField.alpha = 0.8
        
        rectShape = CAShapeLayer()
        rectShape.bounds = self.signInButton.frame
        rectShape.position = self.signInButton.center
        rectShape.path = UIBezierPath(roundedRect: self.signInButton.bounds, byRoundingCorners: [.BottomLeft, .BottomRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).CGPath
        
        self.signInButton.layer.mask = rectShape
        
        self.facebookButton.layer.cornerRadius = cornerRadius
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
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
                Users.sharedInstance.authenticateUserUsingFacebook(token) {
                    
                    let parameters = ["fields": "email, first_name, last_name, picture.type(large)"]
                    let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: parameters, tokenString: token, version: nil, HTTPMethod: "GET")
                    
                    graphRequest.startWithCompletionHandler { (connection, result, error) -> Void in
                        
                        if error != nil {
                            logError(error.localizedDescription)
                            return
                        }
                        
                        CurrentUser.sharedInstance.setData(result)
                        self.performSegueWithIdentifier("unwindToHome", sender: self)
                        
                    }
                }
            }
        })
    
    }
    
    @IBAction func signInButtonPushed(sender: UIButton) {
    
        self.dismissKeyboard()
        
        if let email = self.emailTextField.text, let password = self.passwordTextField.text {
            Users.sharedInstance.authenticateUserUsingEmail(email, password: password) {
                
            }
        }
    
    }
    
    func dismissKeyboard() {
        
        self.view.endEditing(false)
        
    }
    
    func logout() {
        
        self.fbLoginManager.logOut()
        
    }


}
