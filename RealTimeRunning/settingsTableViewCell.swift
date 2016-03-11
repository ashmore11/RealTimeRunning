//
//  settingsTableViewCell.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 04/03/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

class settingsTableViewCell: UITableViewCell {

    @IBOutlet weak var menuLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setTableViewBackgroundGradient(self, topColor: UIColor(red: 0.133, green: 0.133, blue: 0.133, alpha: 1), bottomColor: UIColor.blackColor())

    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        setTableViewBackgroundGradient(self, topColor: UIColor(red: 0.133, green: 0.133, blue: 0.133, alpha: 1), bottomColor: UIColor.blackColor())
    }

}
