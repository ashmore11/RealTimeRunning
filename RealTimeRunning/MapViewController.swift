//
//  MapViewController.swift
//  RealTimeRunning
//
//  Created by bob.ashmore on 20/02/2016.
//  Copyright © 2016 Scott Ashmore. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    var geoEvents:[CLLocationCoordinate2D] = []
    
    @IBOutlet weak var myMapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let coordinateRegion = mapRegion() // MKCoordinateRegionMakeWithDistance(geoEvents.last!, 5000, 5000)
        myMapView.setRegion(coordinateRegion, animated: true)
        let runPoly = MKPolyline(coordinates: &geoEvents, count:geoEvents.count)
        myMapView.addOverlay(runPoly)
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
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
        
        region.center.latitude = (minLat + maxLat) / 2.0
        region.center.longitude = (minLng + maxLng) / 2.0
        
        region.span.latitudeDelta = (maxLat - minLat) * 2
        region.span.longitudeDelta = (maxLng - minLng) * 2
        
        return region
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer    {
        if overlay is MKPolyline {
            
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            
            polylineRenderer.strokeColor = UIColor.redColor()
            
            polylineRenderer.lineWidth = 5
            
            return polylineRenderer
        }
        return MKPolylineRenderer()
    }
    
}
