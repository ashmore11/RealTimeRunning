//
//  RaceTableViewCell.swift
//  RealTimeRunning
//
//  Created by Scott Ashmore on 18/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

class RaceTableViewCell: UITableViewCell {
    
    // MARK: Properties
    
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var competitorsLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    override func awakeFromNib() {
        
        super.awakeFromNib()
    
        // Initialization code
    
    }

    override func setSelected(selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        
    }

}
