//
//  latLonFormats.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 24/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import Foundation
import CoreLocation

enum latLonDisplayTypes {
    case degreeDecimalMinutes
    case degreeDecimal
    case degreeMinutesSeconds
}

typealias GeographicLocation = CLLocationCoordinate2D


func formatLatitude(newLatitude: Double) -> String
{
    var sNorthSouth: String
    var sResult: String
    if newLatitude < 0 {
        sNorthSouth = "S"
    }
    else {
        sNorthSouth = "N"
    }
    
    let newLat = fabs(newLatitude)
    let degrees = floor(newLat)
    let minutes = fabs(60.0 * (newLat - degrees))
    sResult = String(format:"%02.0f %03.3f %@",degrees,minutes,sNorthSouth)
    
    return sResult
}

// Format a decimal lon into DDD MM.MMM E/W
func formatLongitude(newLongitude: Double) -> String
{
    var sEastWest: String
    var sResult: String
    if newLongitude < 0 {
        sEastWest = "W"
    }
    else {
        sEastWest = "E"
    }
    
    let newLon = fabs(newLongitude)
    let degrees = floor(newLon)
    let minutes = fabs(60.0 * (newLon - degrees))
    sResult = String(format:"%03.0f %06.3f %@",degrees,minutes,sEastWest)
    return sResult
}


func formatLatitudePrintA(newLatitude: Double, type: latLonDisplayTypes) ->String
{
    var sNorthSouth: String
    var sResult: String
    if newLatitude < 0 {
        sNorthSouth = "S"
    }
    else {
        sNorthSouth = "N"
    }
    
    let newLat = fabs(newLatitude)
    var degrees = floor(newLat)
    let minutes = fabs(60.0 * (newLat - degrees))
    let wholeMinutes = floor(minutes)
    let decimalMinutes = (minutes-wholeMinutes) * 1000.0
    let wholeSeconds = floor(60.0 * (minutes-wholeMinutes))
    let decimalDegrees = fabs((newLat - degrees)) * 100000.0
    
    switch (type) {
    case .degreeDecimalMinutes:
        sResult = String(format:"%02.0f\u{00B0}%02.0f\u{2032}.%03.0f %@",degrees,wholeMinutes,decimalMinutes,sNorthSouth)
        break
    case .degreeMinutesSeconds:
        sResult = String(format:"%02.0f\u{00B0}%02.0f\u{2032}%02.0f\u{2032}\u{2032} %@",degrees,wholeMinutes,wholeSeconds,sNorthSouth)
        break
    case .degreeDecimal:
        if(newLatitude < 0) {
            degrees *= -1.0
        }
        sResult = String(format:"%+03.0f.%05.0f\u{00B0}",degrees,decimalDegrees)
        break
    }
    return sResult;
}

func formatLongitudePrintA(newLongitude: Double, type: latLonDisplayTypes) ->String
{
    var sEastWest: String
    var sResult: String
    if newLongitude < 0 {
        sEastWest = "W"
    }
    else {
        sEastWest = "E"
    }
    
    let newLon = fabs(newLongitude)
    var degrees = floor(newLon)
    let minutes = fabs(60.0 * (newLon - degrees))
    let wholeMinutes = floor(minutes)
    let decimalMinutes = (minutes-wholeMinutes) * 1000.0
    let wholeSeconds = floor(60.0 * (minutes-wholeMinutes))
    let decimalDegrees = fabs((newLon - degrees)) * 100000.0
    
    switch (type) {
    case .degreeDecimalMinutes:
        sResult = String(format:"%03.0f\u{00B0}%02.0f\u{2032}.%03.0f %@",degrees,wholeMinutes,decimalMinutes,sEastWest)
        break
    case .degreeMinutesSeconds:
        sResult = String(format:"%03.0f\u{00B0}%02.0f\u{2032}%02.0f\u{2032}\u{2032} %@",degrees,wholeMinutes,wholeSeconds,sEastWest)
        break
    case .degreeDecimal:
        if(newLongitude < 0) {
            degrees *= -1.0
        }
        sResult = String(format:"%+04.0f.%05.0f\u{00B0}",degrees,decimalDegrees)
        break
    }
    return sResult;
}

// Format a decimal lat/lon point into DD MM.MMM N/S DDD MM.MMM E/W (Usable on Std. Charts)
func formatLatLon(geoPoint: GeographicLocation) ->String
{
    let result = String(format:"%@ %@",formatLatitude(geoPoint.latitude),formatLongitude(geoPoint.longitude))
    return result
}

func formatLatLonPrintA(geoPoint: GeographicLocation, type: latLonDisplayTypes) ->String
{
    let result = String(format:"%@ %@",formatLatitudePrintA(geoPoint.latitude,type:type),formatLongitudePrintA(geoPoint.longitude,type:type))
    return result
}
