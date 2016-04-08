//
//  CompetitorsTableViewCell.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 07/03/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

class CompetitorsTableViewCell: UITableViewCell {
    
    // MARK: Properties
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var distancePaceLabel: UILabel!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        // Initialization code
        
        setTableViewBackgroundGradient(self, topColor: UIColor(red: 0.100, green: 0.100, blue: 0.100, alpha: 1), bottomColor: UIColor.blackColor())
        
        profileImage.layer.cornerRadius = 5
        profileImage.clipsToBounds = true
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        
    }
    
}
