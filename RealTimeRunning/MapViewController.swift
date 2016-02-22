//
//  MapViewController.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 20/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import MapKit

func degreesToRadian(x: Double) -> Double {
    return (M_PI * x / 180.0)
}

func radiansToDegrees(x: Double) -> Double {
    return (180.0 * x / M_PI)
}

class MapViewController: UIViewController, MKMapViewDelegate {
    var geoEvents:[CLLocationCoordinate2D] = []
    
    @IBOutlet weak var myMapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if geoEvents.count > 0 {
            let coordinateRegion = mapRegion() // MKCoordinateRegionMakeWithDistance(geoEvents.last!, 5000, 5000)
            myMapView.setRegion(coordinateRegion, animated: true)
            let runPoly = MKPolyline(coordinates: &geoEvents, count:geoEvents.count)
            myMapView.addOverlay(runPoly)
            
            // Drop a pin at the start location
            let anotation = MKPointAnnotation()
            anotation.coordinate = geoEvents[0]
            anotation.title = "Race Start"
            anotation.subtitle = "This is the Start location"
            myMapView.addAnnotation(anotation)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapRegion() -> MKCoordinateRegion
    {
        var region:MKCoordinateRegion = MKCoordinateRegion()
        
        var minLat = geoEvents[0].latitude
        var minLng = geoEvents[0].longitude
        var maxLat = geoEvents[0].latitude
        var maxLng = geoEvents[0].longitude
        
        for location in geoEvents  {
            if location.latitude < minLat {
                minLat = location.latitude
            }
            if location.longitude < minLng {
                minLng = location.longitude
            }
            if location.latitude > maxLat {
                maxLat = location.latitude
            }
            if location.longitude > maxLng {
                maxLng = location.longitude
            }
        }
        var spanLat = (maxLat - minLat) * 2
        var spanLon = (maxLng - minLng) * 2
        // if we view the map after we just start then the calculated extent will be to
        // small so if it is less than .6 of a nautical mile (1 minute = 1 nautical mile
        // at the equator) then make the map atleast .6 x .6 of a mile
        
        // 1 degree = 60 miles at equator but as we move north or south then
        // 1 degree gets less so we have to adjust it
        let midLatRads = degreesToRadian(maxLat - minLat)
        let realspanLatLength = (maxLat - minLat) * cos(midLatRads)
        // longitude is the same everywhere so just test it and adjust map extent if needed
        if realspanLatLength < 0.01 {
            spanLat = 0.01 * (1 / cos(midLatRads))
        }
        if(spanLon < 0.01) {
            spanLon = 0.01
        }
        
        region.center.latitude = (minLat + maxLat) / 2.0
        region.center.longitude = (minLng + maxLng) / 2.0
        
        region.span.latitudeDelta = spanLat
        region.span.longitudeDelta = spanLon
        
        return region
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer    {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.redColor()
            polylineRenderer.lineWidth = 3.5
            return polylineRenderer
        }
        return MKPolylineRenderer()
    }
    
}
