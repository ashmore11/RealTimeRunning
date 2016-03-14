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
            imageView.frame = CGRect(x: (self.bounds.width/2.0) - 150, y: (self.bounds.height/2.0) - 150, width: 300, height: 300)
            self.addSubview(imageView)
        }
        
        let headerLabel = UILabel(frame: CGRectMake(0, 0, self.bounds.width, 50))
        headerLabel.center = CGPointMake(self.bounds.width/2.0, 60)
        headerLabel.textAlignment = NSTextAlignment.Center
        headerLabel.text = "RealTimeRunning"
        headerLabel.font = headerLabel.font.fontWithSize(38)
        self.addSubview(headerLabel)
        
        
        let copyrightLabel = UILabel(frame: CGRectMake(0, 0, self.bounds.width, 50))
        copyrightLabel.center = CGPointMake(self.bounds.width/2.0, self.bounds.height - 20)
        copyrightLabel.textAlignment = NSTextAlignment.Center
        copyrightLabel.text = "Copyright © Scott Ashmore 2016"
        copyrightLabel.font = copyrightLabel.font.fontWithSize(17)
        self.addSubview(copyrightLabel)
       
        
    }
}
