//  ViewController.swift
//  enRoute
//  Created by Apurva Kumari on 5/12/18.
//  Copyright © 2018 Apurva Kumari. All rights reserved.

import UIKit
import GoogleMaps

class MapViewController: UIViewController, UITextFieldDelegate {
    
    private let locationManager = CLLocationManager()
    var userCurrentLocation : CLLocation!
    var sourceAddress : String!
    var destinationAddress : String!
    var locationMarker: GMSMarker!
    var originMarker: GMSMarker!
    var destinationMarker: GMSMarker!
    var routePolyline: GMSPolyline!
    var mapTasks = MapRouteTasks()
    var listenToGPSUpdate : Bool!
    
    @IBOutlet weak var resetMapButton: UIButton!
    @IBOutlet weak var monitorRouteSwitch: UISwitch!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var lblRouteInfo: UILabel!
    @IBOutlet weak var lblMonitorRoute: UILabel!
    @IBOutlet weak var showMap: UIButton!
    @IBOutlet weak var showRoute: UIButton!
    @IBOutlet weak var destAdd: UITextField!
    @IBOutlet weak var sourceAdd: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        monitorRouteSwitch.isEnabled = false
        destAdd.delegate = self
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        self.mapView.animate(toZoom: 5)
        listenToGPSUpdate = false;
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
        locationMarker.icon = GMSMarker.markerImage(with: UIColor.blue)
        locationMarker.map = mapView
        locationMarker.title = "Your current location"
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
        monitorRouteSwitch.isEnabled = true
        setuplocationMarker(coordinate: userCurrentLocation.coordinate)
        let route = mapTasks.overviewPolyline["points"] as! String
        let path: GMSPath = GMSPath(fromEncodedPath: route)!
        routePolyline = GMSPolyline(path: path)
        routePolyline.map = mapView
    }
    
    private func clearMapView(){
        mapView.clear()
        mapView.camera = GMSCameraPosition(target: userCurrentLocation.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        setuplocationMarker(coordinate: userCurrentLocation.coordinate)
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
    
    private func showRouteDeviatedPopUp(_ coordinate: CLLocationCoordinate2D){
        let lat: String = String(format: "%f",coordinate.latitude)
        let long: String = String(format: "%f",coordinate.longitude)
        let alertController = UIAlertController(title: "You have devaited from the route",
                                                message: "Current Location:" + lat + "," + long + "\n Do you want re-route?",preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {(action) in
            self.monitorRouteSwitch.setOn(false, animated: true)
            self.listenToGPSUpdate = false
        }
        alertController.addAction(cancelAction)
        
        let reRouteAction = UIAlertAction(title: "ReRoute", style: .default) {(action) in
            let positionString = lat + "," + long
            self.showRouteToUserInner(waypoints: [positionString])
        }
        alertController.addAction(reRouteAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func shouldReRoute() -> Bool {
        let currentLocation: CLLocationCoordinate2D = userCurrentLocation.coordinate
        let routePath: GMSPath = routePolyline.path!
        let geodesic = true
        let tolerance: CLLocationDistance = 40
        return GMSGeometryIsLocationOnPathTolerance(currentLocation, routePath, geodesic, tolerance)
    }
    
    @IBAction func resetButtonClicked(sender: UIButton) {
        self.clearMapView()
        self.monitorRouteSwitch.isEnabled = false;
        destAdd.text = ""
        sourceAdd.text = ""
    }
    
    @IBAction func buttonClicked(sender: UIButton) {
        if monitorRouteSwitch.isOn {
            monitorRouteSwitch.setOn(true, animated:true)
            self.listenToGPSUpdate = true
        } else {
            monitorRouteSwitch.setOn(false, animated:true)
            self.listenToGPSUpdate = false;
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
        self.monitorRouteSwitch.isEnabled = true
        showRouteToUserInner(waypoints: [String]())
    }
    
    func showRouteToUserInner(waypoints : Array<String>) {
        self.destinationAddress = destAdd.text!
        self.sourceAddress = sourceAdd.text!
        mapTasks.getDirections(origin: sourceAddress, destination: destinationAddress, waypoints: waypoints, travelMode: nil, completionHandler: { (status, success) -> Void in
            if success {
                self.clearMapView()
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
        guard let userCurrentLocation = locations.first  else {
            return
        }
        self.userCurrentLocation = userCurrentLocation
        if(self.listenToGPSUpdate) {
            mapView.camera = GMSCameraPosition(target: userCurrentLocation.coordinate, zoom: 10, bearing: 0, viewingAngle: 0)
            
            if(!self.shouldReRoute()) {
                self.showRouteDeviatedPopUp(self.userCurrentLocation.coordinate)
            }
        }
        
        //locationManager.stopUpdatingLocation()
    }
}

extension MapViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        reverseGeocodeCoordinate(position.target)
    }
}




