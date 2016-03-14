//
//  IOSBackgroundSwitcherView.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 14/03/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

class IOSBackgroundSwitcherView: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
        
    }

    override init (frame : CGRect) {
        super.init(frame : frame)
        setupView()
    }

    func setupView() {
        setViewGradient(self)
        
        if let image = UIImage(named: "launchImage.png") {
            let imageView = UIImageView(image: image)
            self.addSubview(imageView)
            self.setupImageConstraints(imageView, mainView:self)
        }
        
        let headerLabel = UILabel(frame: CGRectMake(0, 0, 0, 0))
        headerLabel.textAlignment = NSTextAlignment.Center
        headerLabel.text = "RealTimeRunning"
        headerLabel.font = headerLabel.font.fontWithSize(38)
        self.addSubview(headerLabel)
        self.setupHeaderLabelConstraints(headerLabel, mainView:self)
        
        let copyrightLabel = UILabel(frame: CGRectMake(0, 0, 0, 0))
        copyrightLabel.textAlignment = NSTextAlignment.Center
        copyrightLabel.text = "Copyright © Scott Ashmore 2016"
        copyrightLabel.font = copyrightLabel.font.fontWithSize(17)
        self.addSubview(copyrightLabel)
        self.setupCopyrightLabelConstraints(copyrightLabel, mainView:self)
    }
    
    func setupHeaderLabelConstraints(subView:UIView, mainView:UIView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConstraint = NSLayoutConstraint(item: subView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0)
        mainView.addConstraint(leadingConstraint)

        let trailingConstraint = NSLayoutConstraint(item: subView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: 0)
        mainView.addConstraint(trailingConstraint)

        let topConstraint = NSLayoutConstraint(item: subView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 40)
        mainView.addConstraint(topConstraint)
    }
    
    func setupCopyrightLabelConstraints(subView:UIView, mainView:UIView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConstraint = NSLayoutConstraint(item: subView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0)
        mainView.addConstraint(leadingConstraint)
        
        let trailingConstraint = NSLayoutConstraint(item: subView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: 0)
        mainView.addConstraint(trailingConstraint)
        
        let bottomConstraint = NSLayoutConstraint(item: subView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: -10)
        mainView.addConstraint(bottomConstraint)
    }

    func setupImageConstraints(subView:UIView, mainView:UIView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        
        let widthConstraint = NSLayoutConstraint(item:subView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 300)
        mainView.addConstraint(widthConstraint)
        
        let heightConstraint = NSLayoutConstraint(item: subView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 300)
        mainView.addConstraint(heightConstraint)
        
        let top:NSLayoutConstraint = NSLayoutConstraint(item: subView, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        mainView.addConstraint(top)
        
        let bottom:NSLayoutConstraint = NSLayoutConstraint(item: subView, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        mainView.addConstraint(bottom)
    }

}
