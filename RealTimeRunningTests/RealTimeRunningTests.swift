//
//  RealTimeRunningTests.swift
//  RealTimeRunningTests
//
//  Created by Scott Ashmore on 16/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import XCTest
import UIKit
import Alamofire
import SwiftyJSON
import Alamofire_SwiftyJSON



@testable import RealTimeRunning

class RealTimeRunningTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            delegate.doTest()
        
        
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testSeverRead() {

        let expectation = expectationWithDescription("Alamofire")
        var totalRaces = 0
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let start = NSDate() // <- Start time
        Alamofire.request(.GET, "http://real-time-running.herokuapp.com/api/races").responseSwiftyJSON({ (request, response, json, error) in
            let end = NSDate()   // <- End time
            XCTAssertNil(error, "Alamofire request error \(error)")
            
            for (_, value) in json {
                XCTAssertNotNil(value["_id"].string, "Expected non-nil ID string")
                XCTAssertNotNil(value["createdAt"].string, "CreatedAt is nil")
                XCTAssertNotNil(formatter.dateFromString(value["createdAt"].string!), "createdAt not a valid string")
                XCTAssertNotNil(value["competitors"].array,"Competitors array not valid")
                XCTAssertNotNil(value["distance"].int,"distance not a valid number")
                XCTAssertNotNil(value["live"].bool, "live is not a valid bool")
                totalRaces++
            }
            expectation.fulfill()
            let timeInterval: Double = end.timeIntervalSinceDate(start) // <- Difference in seconds (double)
            if timeInterval < 1.0 {
                print("XXXXXXXXXXXXX -> Request time: \(timeInterval) seconds Races: \(totalRaces) <- XXXXXXXXXXXXX")
            }
            else {
                XCTFail("REQUEST TIME FAIL -> Request time: \(timeInterval) seconds Races: \(totalRaces) <-REQUEST TIME FAIL")
            }
            
        })
        
        waitForExpectationsWithTimeout(10.0, handler: nil)
      
        
    }

}
