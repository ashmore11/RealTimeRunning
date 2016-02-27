//
//  MapViewController.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 20/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    var geoEvents:[CLLocationCoordinate2D] = []
    let manager = CLLocationManager()
    
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
        else {
            // We have no data in the array so get our current location
            // and set map center to it
            manager.delegate = self
            manager.requestLocation()
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("Found user's location: \(location)")
            // Cetner map at our current location wit a span of 2 kilometers North-South and East-West
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
            myMapView.setRegion(coordinateRegion, animated: true)
            
            // Drop a pin at the current location
            let anotation = MKPointAnnotation()
            anotation.coordinate = location.coordinate
            anotation.title = "You are here"
            anotation.subtitle = "This is the Start location"
            
            myMapView.addAnnotation(anotation)

        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapRegion() -> MKCoordinateRegion
    {
        var region:MKCoordinateRegion = MKCoordinateRegion()
        // Go through the array and get the span that it encompasses
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
        // 1 Degree of Lattitude at Equator = 60 Nautical Miles
        // 0.1 Degree = 6 Miles
        // 0.01 Degree = 0.6 Miles = 1,111 Meters
        // But 1 degree of Latitude at the Nort or South Pole is 0 Miles
        // At my Latitude of 53 Degrees North 1 degree of lattitude = 1 * cos(my Latitude in radians) = .6 Miles
        // if we view the map after we just start then the calculated extent will be to
        // small so if it is less than .6 of a nautical mile (1 minute = 1 nautical mile
        // at the equator) then make the map at least .6 x .6 of a mile
        
        // 1 degree = 60 miles at equator but as we move north or south then
        // 1 degree gets less so we have to adjust it
        // Convert degrees to radians because the math functions require all degree
        // measurements in radians
        let midLatRads = degreesToRadian(maxLat - minLat)
        // Adjust for my current latitude
        let realspanLatLength = (maxLat - minLat) * cos(midLatRads)
        // longitude is the same everywhere so just test it and adjust map extent if needed
        if realspanLatLength < 0.01 {
            spanLat = 0.01 * (1 / cos(midLatRads))
        }
        if(spanLon < 0.01) {
            spanLon = 0.01
        }
        // Set the map center
        region.center.latitude = (minLat + maxLat) / 2.0
        region.center.longitude = (minLng + maxLng) / 2.0
        // Set the size of the map to display
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
