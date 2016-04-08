//
//  UsernameAlert.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 5/04/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import Foundation
import UIKit

public class UsernameAlert: UIViewController, UITextFieldDelegate {
    
    let window = UIApplication.sharedApplication().keyWindow! as UIWindow
    
    var alertWidth: CGFloat!
    let topPadding: CGFloat = 5.0
    let titleHeight: CGFloat = 40.0
    var textHeight: CGFloat = 90.0
    let textFieldHeight: CGFloat = 50.0
    let buttonHeight: CGFloat = 55.0
    let bottomPadding: CGFloat = 25.0
    
    var baseView = UIView()
    var titleLabel = UILabel()
    var subTitleLabel = UITextView()
    var contentView = UIView()
    var textField = UITextField()
    var button = UIButton()
    
    var viewColor = UIColor.blackColor()
    
    var tmpContentViewFrameOrigin: CGPoint?
    var keyboardHasBeenShown: Bool = false
    
    let events = EventManager()
    
    required public init?(coder aDecoder: NSCoder) {
        
        fatalError("NSCoding not supported")
        
    }
    
    required public init() {
        
        super.init(nibName: nil, bundle: nil)
        
        self.alertWidth = self.window.frame.size.width / 1.35
        
        // Set up main view
        self.view.frame = UIScreen.mainScreen().bounds
        self.view.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        self.view.addSubview(self.baseView)
        
        // Base View
        self.baseView.frame = self.view.frame
        self.baseView.addSubview(self.contentView)
        
        // Content View
        self.contentView.backgroundColor = UIColor(white:1, alpha:1)
        self.contentView.layer.cornerRadius = 5.0
        self.contentView.layer.masksToBounds = true
        self.contentView.layer.borderWidth = 0.5
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.subTitleLabel)
        self.contentView.addSubview(self.textField)
        self.contentView.addSubview(self.button)
        
        // Title
        self.titleLabel.numberOfLines = 1
        self.titleLabel.textAlignment = .Center
        self.titleLabel.font = UIFont(name: "Oswald-Regular", size: 20)
        self.titleLabel.frame = CGRect(x:12, y: self.topPadding, width: self.alertWidth - 24, height: self.titleHeight + 10)
        
        // Sub Title
        self.subTitleLabel.editable = false
        self.subTitleLabel.textAlignment = .Center
        self.subTitleLabel.textContainerInset = UIEdgeInsetsZero
        self.subTitleLabel.textContainer.lineFragmentPadding = 0
        self.subTitleLabel.font = UIFont(name: "Oswald-Regular", size: 14)
        
        // Text Field
        self.textField.delegate = self
        self.textField.borderStyle = .RoundedRect
        self.textField.font = UIFont(name: "Oswald-Regular", size: 14)
        self.textField.autocapitalizationType = .AllCharacters
        self.textField.textAlignment = .Center
        self.textField.clearButtonMode = .WhileEditing
        self.textField.layer.masksToBounds = true
        self.textField.layer.borderWidth = 1.0
        self.textField.layer.borderColor = viewColor.CGColor
        self.textField.layer.cornerRadius = 3.0
        self.textField.placeholder = "USERNAME"
        
        // Button
        self.button.layer.masksToBounds = true
        self.button.layer.cornerRadius = 3.0
        self.button.setTitle("CREATE", forState: .Normal)
        self.button.titleLabel?.font = UIFont(name: "Oswald-Regular", size: 14)
        self.button.backgroundColor = self.viewColor
        self.button.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        self.button.addTarget(self, action: #selector(self.buttonTapped), forControlEvents: .TouchUpInside)
        
        // Colours
        self.contentView.backgroundColor = UIColorFromRGB(0xFFFFFF)
        self.titleLabel.textColor = UIColorFromRGB(0x4D4D4D)
        self.subTitleLabel.textColor = UIColorFromRGB(0x4D4D4D)
        self.contentView.layer.borderColor = UIColorFromRGB(0xCCCCCC).CGColor
        
    }
    
    override public func viewWillLayoutSubviews() {
        
        super.viewWillLayoutSubviews()
        
        let windowSize = self.window.frame.size
        
        self.view.frame.size = windowSize
        
        let subTitleHeight = self.subTitleLabel.sizeThatFits(CGSizeMake(self.alertWidth - 24, CGFloat.max)).height
        let heights: [CGFloat] = [self.topPadding, self.titleHeight, subTitleHeight, self.buttonHeight, self.textFieldHeight, self.bottomPadding]
        let alertHeight = heights.reduce(0, combine: { $0 + $1 })
        
        // Set frames
        let x = (windowSize.width - self.alertWidth) / 2
        var y = (windowSize.height - alertHeight) / 2
        self.contentView.frame = CGRect(x: x, y: y, width: self.alertWidth, height: alertHeight)
        
        // Sub Title
        y = self.topPadding + self.titleHeight
        self.subTitleLabel.frame = CGRect(x: 12, y: y, width: self.alertWidth - 24, height: subTitleHeight)
        
        // Text fields
        y += subTitleHeight + 20
        self.textField.frame = CGRect(x: 16, y: y, width: self.alertWidth - 32, height: 40)
        
        // Buttons
        y += self.textFieldHeight
        self.button.frame = CGRect(x: 16, y: y, width: self.alertWidth - 32, height: 40)
        
    }
    
    override public func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
        
    }
    
    override public func viewDidDisappear(animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(UIKeyboardWillShowNotification)
        NSNotificationCenter.defaultCenter().removeObserver(UIKeyboardWillHideNotification)
        
    }
    
    public func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        
        let newLength = text.characters.count + string.characters.count - range.length
        
        return newLength <= 16
        
    }
    
    func buttonTapped(btn: UIButton) {
       
        self.events.trigger("buttonTapped")
        
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        self.keyboardHasBeenShown = true
        self.tmpContentViewFrameOrigin = self.contentView.frame.origin
        
        guard let userInfo = notification.userInfo else { return }
        guard let beginKeyBoardFrame = userInfo[UIKeyboardFrameBeginUserInfoKey]?.CGRectValue.origin.y else { return }
        guard let endKeyBoardFrame = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.origin.y else { return }
        
        let newContentViewFrameY = beginKeyBoardFrame - endKeyBoardFrame - self.contentView.frame.origin.y + 30
        
        self.contentView.frame.origin.y -= newContentViewFrameY
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        if self.keyboardHasBeenShown {
            
            if self.tmpContentViewFrameOrigin != nil {
                
                self.contentView.frame.origin.y = self.tmpContentViewFrameOrigin!.y
                
            }
            
            self.keyboardHasBeenShown = false
            
        }
        
    }
    
    public func showView(title: String, subTitleLabel: String) {
        
        self.view.alpha = 0
        
        self.window.addSubview(self.view)
        
        self.titleLabel.text = title
        self.subTitleLabel.text = subTitleLabel
        
        self.baseView.frame.origin.y = -400
        UIView.animateWithDuration(0.2, animations: {
            
            self.baseView.center.y = self.window.center.y + 15
            self.view.alpha = 1
            
            }, completion: { finished in
                
                UIView.animateWithDuration(0.2, animations: {
                    
                    self.baseView.center = self.window.center
                    
                })
                
        })
        
    }
    
    public func errorHappened(message: String?) {
        
        let animation = CABasicAnimation(keyPath: "position")
        
        animation.duration = 0.05
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = NSValue(CGPoint: CGPointMake(self.contentView.center.x - 5, self.contentView.center.y))
        animation.toValue = NSValue(CGPoint: CGPointMake(self.contentView.center.x + 5, self.contentView.center.y))
        
        self.contentView.layer.addAnimation(animation, forKey: "position")
        
        self.textField.layer.borderColor = UIColor.redColor().CGColor
        self.textField.textColor = UIColor.redColor()
        
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(self.resetTextField), userInfo: nil, repeats: false)
        
    }
    
    func resetTextField() {
                
        self.textField.layer.borderColor = UIColor.blackColor().CGColor
        self.textField.textColor = UIColor.blackColor()
        
    }
    
    public func hideView() {
        
        UIView.animateWithDuration(0.2, animations: { self.view.alpha = 0 }, completion: { finished in

            self.view.removeFromSuperview()
                
        })
        
    }
    
}
