//
//  settingsTableViewController.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 25/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit

class settingsTableViewController: UITableViewController {

    @IBOutlet weak var metricOrImperialSegmentCtl: UISegmentedControl!

    @IBAction func didChangeMeasure(sender: AnyObject) {
    
        switch metricOrImperialSegmentCtl.selectedSegmentIndex
        {
            case 0:
                print("Segment Changed Metric selected")
            case 1:
                print("Segment Changed Imperial selected")
            default:
                break 
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        self.tableView.backgroundColor = UIColor.blackColor()
        
        metricOrImperialSegmentCtl.selectedSegmentIndex = 0

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Make the seperator lines between cells go all the way to the view's left edge
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layoutMargins = UIEdgeInsetsZero
        cell.separatorInset = UIEdgeInsetsZero
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.layoutMargins = UIEdgeInsetsZero
    }

}
