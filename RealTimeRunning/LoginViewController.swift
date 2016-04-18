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
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var usernameHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var usernameMarginConstraint: NSLayoutConstraint!
    
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
        
        self.usernameTextField.borderStyle = .None
        self.usernameTextField.layer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.8).CGColor
        self.usernameTextField.alpha = 0.8
        self.usernameHeightConstraint.constant = 0
        self.usernameMarginConstraint.constant = 0
        
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
            
            if(result.grantedPermissions.contains("email")) {
                
                let token = FBSDKAccessToken.currentAccessToken().tokenString
                
                Users.sharedInstance.authenticateUserUsingFacebook(token) { data in
                    
                    guard let id = data["id"] as? String else { return }
                    
                    if let user = Users.sharedInstance.findOne(id) {
                        
                        CurrentUser.sharedInstance.setCurrentUser(user)
                    
                        self.performSegueWithIdentifier("unwindToHome", sender: self)
                    
                    } else {
                        
                        self.createUser(id, data: data)
                        
                    }
                }
            }
        })
    
    }
    
    @IBAction func signInButtonPushed(sender: UIButton) {
    
        self.dismissKeyboard()
        
        if let email = self.emailTextField.text, let password = self.passwordTextField.text {
            
            Users.sharedInstance.authenticateUserUsingEmail(email, password: password) { data in
                
                guard let id = data["id"] as? String else { return }
                
                if let user = Users.sharedInstance.findOne(id) {
                    
                    CurrentUser.sharedInstance.setCurrentUser(user)
                    
                    self.performSegueWithIdentifier("unwindToHome", sender: self)
                    
                } else {
                    
                    print("user not found...")
                    
                }
            }
        }
    
    }
    
    func createUser(id: String, data: NSDictionary) {
        
        self.showUsernameAlert { username in
            
            if let email = data["email"] as? String, let imageURL = data["profileImageURL"] as? String {
                
                let parameters = [
                    "username": username,
                    "email": email,
                    "image": imageURL,
                    "points": 0
                ]
                
                Users.sharedInstance.insert(id, fields: parameters) { user in
                    
                    if let user = Users.sharedInstance.findOne(id) {
                        
                        CurrentUser.sharedInstance.setCurrentUser(user)
                        
                        self.performSegueWithIdentifier("unwindToHome", sender: self)
                        
                    }
                }
            }
        }
        
    }
    
    func showUsernameAlert(completionHandler: (username: String) -> Void) {
        
        let alert = UsernameAlert()
        
        let title = "HELLO \(CurrentUser.sharedInstance.firstName!.uppercaseString)!"
        let subTitle = "Create a username that is greater than 3 characters and less than 17. Username's must only contain letters and numbers."
        
        alert.showView(title, subTitleLabel: subTitle)
        
        alert.events.listenTo("buttonTapped", action: {
            if let username = alert.textField.text {
                if Users.sharedInstance.list.indexOf({ $0.username == username }) != nil {
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
    
    func dismissKeyboard() {
        
        self.view.endEditing(false)
        
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(0.5, animations: {
            self.usernameHeightConstraint.constant = 50
            self.usernameMarginConstraint.constant = 1
            self.view.layoutIfNeeded()
        })
        
    }


}
