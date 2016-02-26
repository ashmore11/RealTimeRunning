//
//  RawTableViewCell.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 24/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

class RawTableViewCell: UITableViewCell {
    @IBOutlet weak var latLonLabel: UILabel!
    @IBOutlet weak var gpsDataLabel: UILabel!
    @IBOutlet weak var pedometerDataLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
