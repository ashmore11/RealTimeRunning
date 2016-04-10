//
//  AlertViewController.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 07/04/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

public class AlertViewController: UIViewController {
    
    let window = UIApplication.sharedApplication().keyWindow! as UIWindow
    let events: EventManager = EventManager()
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UITextView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var contentView: UIView!
    
    required public init?(coder aDecoder: NSCoder) {
        
        fatalError("NSCoding not supported")
        
    }
    
    required public init() {
        
        super.init(nibName: nil, bundle: nil)
        
        // Main View
        self.view.frame = UIScreen.mainScreen().bounds
        self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        
        // Content View
        self.contentView.backgroundColor = UIColor.whiteColor()
        self.contentView.layer.cornerRadius = 5
        self.contentView.layer.masksToBounds = true
        self.contentView.layer.borderWidth = 0.5

        // Sub Title
        self.subTitleLabel.editable = false
        self.subTitleLabel.textContainerInset = UIEdgeInsetsZero
        self.subTitleLabel.textContainer.lineFragmentPadding = 0
        
        // Done Button
        self.doneButton.layer.cornerRadius = 3
        self.doneButton.layer.masksToBounds = true
        
        // Colours
        self.contentView.backgroundColor = UIColorFromRGB(0xFFFFFF)
        self.titleLabel.textColor = UIColorFromRGB(0x4D4D4D)
        self.subTitleLabel.textColor = UIColorFromRGB(0x4D4D4D)
        self.contentView.layer.borderColor = UIColorFromRGB(0xCCCCCC).CGColor
        
    }
    
    override public func viewWillLayoutSubviews() {
        
        super.viewWillLayoutSubviews()
        
        let contentSize = self.subTitleLabel.sizeThatFits(self.subTitleLabel.bounds.size)
        var frame = self.subTitleLabel.frame
        frame.size.height = contentSize.height
        self.subTitleLabel.frame = frame
        
    }
    
    @IBAction func doneButtonPushed(sender: UIButton) {
    
        self.events.trigger("doneButtonPushed")
    
    }
    
    func show(title: String, subTitle: String) {
        
        self.view.alpha = 0
        
        self.window.addSubview(self.view)
        
        self.titleLabel.text = title
        self.subTitleLabel.text = subTitle
        
        print(self.window.center.y + 15, self.window.center.y)
        
        self.contentView.frame.origin.y = -400
        UIView.animateWithDuration(0.2, animations: {
            
            self.contentView.center.y = self.window.center.y + 15
            self.view.alpha = 1
            
            }, completion: { finished in
                
                UIView.animateWithDuration(0.2, animations: {
                    
                    self.contentView.center = self.window.center
                    
                })
                
        })
        
    }
    
    func hide() {
        
        UIView.animateWithDuration(0.2, animations: { self.view.alpha = 0 }, completion: { finished in
            
            self.view.removeFromSuperview()
            
        })
        
    }
    
}
