//
//  SCLAlertView.swift
//  SCLAlertView Example
//
//  Created by Viktor Radchenko on 6/5/14.
//  Copyright (c) 2014 Viktor Radchenko. All rights reserved.
//

import Foundation
import UIKit

// Action Types
public enum SCLActionType {
    
    case None, Selector, Closure
    
}

// Button sub-class
public class SCLButton: UIButton {
    
    var actionType = SCLActionType.None
    var target:AnyObject!
    var selector:Selector!
    var action:(()->Void)!
    
    public init() {
        super.init(frame: CGRectZero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override public init(frame:CGRect) {
        super.init(frame:frame)
    }
    
}

// Allow alerts to be closed/renamed in a chainable manner
// Example: SCLAlertView().showSuccess(self, title: "Test", subTitle: "Value").close()
public class SCLAlertViewResponder {
    
    let alertview: SCLAlertView
    
    // Initialisation and Title/Subtitle/Close functions
    public init(alertview: SCLAlertView) {
        self.alertview = alertview
    }
    
    public func setTitle(title: String) {
        self.alertview.labelTitle.text = title
    }
    
    public func setSubTitle(subTitle: String) {
        self.alertview.viewText.text = subTitle
    }
    
    public func close() {
        self.alertview.hideView()
    }
    
}

// The Main Class
public class SCLAlertView: UIViewController {
    
    let kDefaultShadowOpacity: CGFloat = 0.7
    let kCircleTopPosition: CGFloat = -12.0
    let kCircleBackgroundTopPosition: CGFloat = -15.0
    let kCircleHeight: CGFloat = 56.0
    let kTitleTop:CGFloat = 30.0
    let kTitleHeight:CGFloat = 40.0
    let kWindowWidth: CGFloat = 280.0
    var kWindowHeight: CGFloat = 200.0
    var kTextHeight: CGFloat = 90.0
    let kTextFieldHeight: CGFloat = 50.0
    let kButtonHeight: CGFloat = 65.0
    
    // Font
    let kDefaultFont = "Oswald-Regular"
    
    // UI Colour
    var viewColor = UIColor()
    var pressBrightnessFactor = 0.85
    
    // UI Options
    public var showCloseButton = true
    public var shouldAutoDismiss = false
    public var contentViewCornerRadius : CGFloat = 5.0
    public var fieldCornerRadius : CGFloat = 3.0
    public var buttonCornerRadius : CGFloat = 3.0
    public var iconTintColor: UIColor?
    
    // Actions
    public var hideWhenBackgroundViewIsTapped = false
    
    // Members declaration
    var baseView = UIView()
    var labelTitle = UILabel()
    var viewText = UITextView()
    var contentView = UIView()
    var durationTimer: NSTimer!
    private var inputs = [UITextField]()
    internal var buttons = [SCLButton]()
    private var selfReference: SCLAlertView?
    
    required public init?(coder aDecoder: NSCoder) {
        
        fatalError("NSCoding not supported")
        
    }
    
    required public init() {
        
        super.init(nibName: nil, bundle: nil)
        
        // Set up main view
        view.frame = UIScreen.mainScreen().bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        view.backgroundColor = UIColor(red:0, green:0, blue:0, alpha:kDefaultShadowOpacity)
        view.addSubview(baseView)
        
        // Base View
        baseView.frame = view.frame
        baseView.addSubview(contentView)
        
        // Content View
        contentView.backgroundColor = UIColor(white:1, alpha:1)
        contentView.layer.cornerRadius = contentViewCornerRadius
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 0.5
        contentView.addSubview(labelTitle)
        contentView.addSubview(viewText)
        
        // Title
        labelTitle.numberOfLines = 1
        labelTitle.textAlignment = .Center
        labelTitle.font = UIFont(name: kDefaultFont, size:20)
        labelTitle.frame = CGRect(x:12, y:kTitleTop, width: kWindowWidth - 24, height:kTitleHeight + 10)
        
        // View text
        viewText.editable = false
        viewText.textAlignment = .Center
        viewText.textContainerInset = UIEdgeInsetsZero
        viewText.textContainer.lineFragmentPadding = 0;
        viewText.font = UIFont(name: kDefaultFont, size:14)
        
        // Colours
        contentView.backgroundColor = UIColorFromRGB(0xFFFFFF)
        labelTitle.textColor = UIColorFromRGB(0x4D4D4D)
        viewText.textColor = UIColorFromRGB(0x4D4D4D)
        contentView.layer.borderColor = UIColorFromRGB(0xCCCCCC).CGColor
        
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
        
    }
    
    override public func viewWillLayoutSubviews() {
        
        super.viewWillLayoutSubviews()
        
        let rv = UIApplication.sharedApplication().keyWindow! as UIWindow
        let sz = rv.frame.size
        
        view.frame.size = sz
        
        let maxHeight = sz.height - 100
        
        var consumedHeight = CGFloat(0)
        consumedHeight += kTitleTop + kTitleHeight
        consumedHeight += 14
        consumedHeight += kButtonHeight * CGFloat(buttons.count)
        consumedHeight += kTextFieldHeight * CGFloat(inputs.count)
        
        let maxViewTextHeight = maxHeight - consumedHeight
        let viewTextWidth = kWindowWidth - 24
        let suggestedViewTextSize = viewText.sizeThatFits(CGSizeMake(viewTextWidth, CGFloat.max))
        let viewTextHeight = min(suggestedViewTextSize.height, maxViewTextHeight)
        let windowHeight = consumedHeight + viewTextHeight
        
        // Set frames
        let x = (sz.width - kWindowWidth) / 2
        var y = (sz.height - windowHeight - (kCircleHeight / 8)) / 2
        contentView.frame = CGRect(x: x, y: y, width: kWindowWidth, height: windowHeight)
        contentView.layer.cornerRadius = contentViewCornerRadius
        
        //adjust Title frame based on circularIcon show/hide flag
        let titleOffset: CGFloat = -12.0
        labelTitle.frame = labelTitle.frame.offsetBy(dx: 0, dy: titleOffset)
        
        // Subtitle
        y = kTitleTop + kTitleHeight + titleOffset
        viewText.frame = CGRect(x: 12, y: y, width: kWindowWidth - 24, height: kTextHeight)
        viewText.frame = CGRect(x: 12, y: y, width: viewTextWidth, height: viewTextHeight)
        y += viewTextHeight + 24.0
        
        // Text fields
        for txt in inputs {
            txt.frame = CGRect(x: 16, y: y, width:kWindowWidth - 32, height: 40)
            txt.layer.cornerRadius = fieldCornerRadius
            y += kTextFieldHeight
        }
        
        // Buttons
        for btn in buttons {
            btn.frame = CGRect(x: 16, y: y, width: kWindowWidth - 32, height: 50)
            btn.layer.cornerRadius = buttonCornerRadius
            y += kButtonHeight
        }
        
    }
    
    override public func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil);
        
    }
    
    override public func viewDidDisappear(animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(UIKeyboardWillShowNotification)
        NSNotificationCenter.defaultCenter().removeObserver(UIKeyboardWillHideNotification)
        
    }
    
    public func addTextField(title: String?) -> UITextField {
        
        kWindowHeight += kTextFieldHeight
        
        let txt = UITextField()
        
        txt.borderStyle = UITextBorderStyle.RoundedRect
        txt.font = UIFont(name: kDefaultFont, size: 14)
        txt.autocapitalizationType = UITextAutocapitalizationType.Words
        txt.clearButtonMode = UITextFieldViewMode.WhileEditing
        txt.layer.masksToBounds = true
        txt.layer.borderWidth = 1.0
        txt.placeholder = title!
        
        contentView.addSubview(txt)
        inputs.append(txt)
        
        return txt
        
    }
    
    public func addButton(title: String, action: () -> Void) -> SCLButton {
        
        let btn = addButton(title)

        btn.action = action
        
        btn.addTarget(self, action: #selector(self.buttonTapped), forControlEvents: .TouchUpInside)
        
        return btn
        
    }
    
    private func addButton(title: String) -> SCLButton {
        
        kWindowHeight += kButtonHeight

        let btn = SCLButton()
        
        btn.layer.masksToBounds = true
        btn.setTitle(title, forState: .Normal)
        btn.titleLabel?.font = UIFont(name:kDefaultFont, size: 14)
        
        contentView.addSubview(btn)
        buttons.append(btn)
        
        return btn
        
    }
    
    func buttonTapped(btn: SCLButton) {
       
        btn.action()
        
    }
    
    var tmpContentViewFrameOrigin: CGPoint?
    var keyboardHasBeenShown: Bool = false
    
    func keyboardWillShow(notification: NSNotification) {
        
        keyboardHasBeenShown = true
        
        guard let userInfo = notification.userInfo else {return}
        guard let beginKeyBoardFrame = userInfo[UIKeyboardFrameBeginUserInfoKey]?.CGRectValue.origin.y else {return}
        guard let endKeyBoardFrame = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.origin.y else {return}
        
        tmpContentViewFrameOrigin = self.contentView.frame.origin
        
        let newContentViewFrameY = beginKeyBoardFrame - endKeyBoardFrame - self.contentView.frame.origin.y + 30
        self.contentView.frame.origin.y -= newContentViewFrameY
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        if(keyboardHasBeenShown) {
            
            if(self.tmpContentViewFrameOrigin != nil) {
                self.contentView.frame.origin.y = self.tmpContentViewFrameOrigin!.y
            }
            
            keyboardHasBeenShown = false
            
        }
        
    }
    
    public func show(title: String, subTitle: String) -> SCLAlertViewResponder {
        
        view.alpha = 0
        let rv = UIApplication.sharedApplication().keyWindow! as UIWindow
        rv.addSubview(view)
        view.frame = rv.bounds
        baseView.frame = rv.bounds
        viewColor = UIColor.blackColor()
        
        // Title
        self.labelTitle.text = title
        
        // Subtitle
        viewText.text = subTitle
        // Adjust text view size, if necessary
        let str = subTitle as NSString
        let attr = [NSFontAttributeName:viewText.font ?? UIFont()]
        let sz = CGSize(width: kWindowWidth - 24, height:90)
        let r = str.boundingRectWithSize(sz, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes:attr, context:nil)
        let ht = ceil(r.size.height)
        if ht < kTextHeight {
            kWindowHeight -= (kTextHeight - ht)
            kTextHeight = ht
        }
        
        for txt in inputs {
            txt.layer.borderColor = viewColor.CGColor
        }
        
        for btn in buttons {
            btn.backgroundColor = viewColor
            btn.setTitleColor(UIColorFromRGB(0xFFFFFF), forState:UIControlState.Normal)
        }
        
        // Animate in the alert view
        self.baseView.frame.origin.y = -400
        UIView.animateWithDuration(0.2, animations: {
            self.baseView.center.y = rv.center.y + 15
            self.view.alpha = 1
            }, completion: { finished in
                UIView.animateWithDuration(0.2, animations: {
                    self.baseView.center = rv.center
                })
        })
        
        // Chainable objects
        return SCLAlertViewResponder(alertview: self)
        
    }
    
    public func errorHappened(message: String?) {
        
        let animation = CABasicAnimation(keyPath: "position")
        
        animation.duration = 0.05
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = NSValue(CGPoint: CGPointMake(self.contentView.center.x - 5, self.contentView.center.y))
        animation.toValue = NSValue(CGPoint: CGPointMake(self.contentView.center.x + 5, self.contentView.center.y))
        
        self.contentView.layer.addAnimation(animation, forKey: "position")
        
        self.inputs.forEach({ textField in
            textField.layer.borderColor = UIColor.redColor().CGColor
            textField.textColor = UIColor.redColor()
        })
        
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(self.resetTextField), userInfo: nil, repeats: false)
        
    }
    
    func resetTextField() {
        
        self.inputs.forEach({ textField in
                
            textField.layer.borderColor = UIColor.blackColor().CGColor
            textField.textColor = UIColor.blackColor()
            
        })
        
    }
    
    // Close SCLAlertView
    public func hideView() {
        
        UIView.animateWithDuration(0.2, animations: {
            self.view.alpha = 0
            }, completion: { finished in
                
                for button in self.buttons {
                    button.action = nil
                }
                
                self.view.removeFromSuperview()
                self.selfReference = nil
        })
        
    }
    
}
