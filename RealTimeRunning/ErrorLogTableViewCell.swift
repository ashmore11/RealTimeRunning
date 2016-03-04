//
//  ErrorLogTableViewCell.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 03/03/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

class ErrorLogTableViewCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var logLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
