//  ViewController.swift
//  enRoute
//  Created by Apurva Kumari on 5/12/18.
//  Copyright © 2018 Apurva Kumari. All rights reserved.

import UIKit
import GoogleMaps

class MapViewController: UIViewController, UITextFieldDelegate{
    
    private let locationManager = CLLocationManager()
    var locationMarker: GMSMarker!
    var originMarker: GMSMarker!
    var destinationMarker: GMSMarker!
    var routePolyline: GMSPolyline!
    var mapTasks = MapRouteTasks()
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var lblRouteInfo: UILabel!
    @IBOutlet weak var showMap: UIButton!
    @IBOutlet weak var showRoute: UIButton!
    @IBOutlet weak var searchRoute: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchRoute.delegate = self
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func textFieldShouldReturn(_ searchRoute: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    private func setuplocationMarker(coordinate: CLLocationCoordinate2D) {
        locationMarker = GMSMarker(position: coordinate)
        locationMarker.map = mapView
    }
    
    private func configureMapAndMarkersForRoute() {
        mapView.camera = GMSCameraPosition.camera(withTarget: mapTasks.originCoordinate, zoom: 9.0)
        originMarker = GMSMarker(position: self.mapTasks.originCoordinate)
        originMarker.map = self.mapView
        originMarker.icon = GMSMarker.markerImage(with: UIColor.green)
        originMarker.title = self.mapTasks.originAddress
        
        destinationMarker = GMSMarker(position: self.mapTasks.destinationCoordinate)
        destinationMarker.map = self.mapView
        destinationMarker.icon = GMSMarker.markerImage(with: UIColor.red)
        destinationMarker.title = self.mapTasks.destinationAddress
    }
    private func drawRoute() {
        //let route = mapTasks.overviewPolyline["points"] as String
        let route = mapTasks.overviewPolyline["points"] as! String
        let path: GMSPath = GMSPath(fromEncodedPath: route)!
        routePolyline = GMSPolyline(path: path)
        routePolyline.map = mapView
    }
    private func displayRouteInfo() {
        self.lblRouteInfo.text = mapTasks.totalDuration
    }
    
    private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = GMSGeocoder()
        geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
            guard let address = response?.firstResult(), let lines = address.lines else {
                return
            }
            self.lblRouteInfo.text = lines.joined(separator: " ")
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }

    }
    @IBAction func changeMapType(sender: AnyObject) {
        let actionSheet = UIAlertController(title: "Map Types", message: "Select map type:", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let normalMapTypeAction = UIAlertAction(title: "Normal", style: UIAlertActionStyle.default) { (alertAction) -> Void in
            self.mapView.mapType = GMSMapViewType.normal
        }
        
        let terrainMapTypeAction = UIAlertAction(title: "Terrain", style: UIAlertActionStyle.default) { (alertAction) -> Void in
            self.mapView.mapType = GMSMapViewType.terrain
        }
        
        let hybridMapTypeAction = UIAlertAction(title: "Hybrid", style: UIAlertActionStyle.default) { (alertAction) -> Void in
            self.mapView.mapType = GMSMapViewType.hybrid
        }
        
        let cancelAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel) { (alertAction) -> Void in
            
        }
        actionSheet.addAction(normalMapTypeAction)
        actionSheet.addAction(terrainMapTypeAction)
        actionSheet.addAction(hybridMapTypeAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func showRouteToUser(sender: AnyObject) {
        let destination: String = searchRoute.text!
        let source : String = lblRouteInfo.text!
        print(source + "/n")
        print(destination + "/n")
        mapTasks.getDirections(origin: source, destination: destination, waypoints: nil, travelMode: nil, completionHandler: { (status, success) -> Void in
            if success {
                self.configureMapAndMarkersForRoute()
                self.drawRoute()
                self.displayRouteInfo()
            }
            else {
                print(status)
            }
        })
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        locationManager.startUpdatingLocation()
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        setuplocationMarker(coordinate: location.coordinate)
        locationManager.stopUpdatingLocation()
    }
 }

extension MapViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        reverseGeocodeCoordinate(position.target)
    }
}




