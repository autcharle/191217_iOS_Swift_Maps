//
//  ViewController.swift
//  Maps
//
//  Created by Tuyen Tran on 12/12/19.
//  Copyright © 2019 Tuyen Tran. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController
{
    private let locationManager = CLLocationManager()
    private var previousLocation: CLLocation?
    private var myMarker: MKPointAnnotation?
    private var previousMarker: MKPointAnnotation?
    private let geocoder = CLGeocoder()
    private var directionsArray: [MKDirections] = []
    
    private let regionInMeters: Double = 100
    private let withPreviousDistance: Double = 5
    
    private var startUpdatingLocation: Bool = true
    private var placedMarker: Bool = false
    private var nextRegionChangeIsFromUserInteraction: Bool = false
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var myLocationBtn: UIButton!
    @IBOutlet weak var markerBtn: UIButton!
    @IBOutlet weak var routesBtn: UIButton!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var myPin: UIImageView!
    @IBOutlet weak var addAnnotationsBtn: UIButton!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        loadUI()
        checkLocationServices()
    }
    
    func loadUI()
    {
        addressLabel.text = ""
        myLocationBtn.layer.cornerRadius = 5.0
        markerBtn.layer.cornerRadius = 5.0
        myPin.isHidden = true
    }
    
    func setupLocationManager()
    {
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func centerViewOnUserLocation()
    {
        if let location = locationManager.location?.coordinate
        {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func checkLocationServices()
    {
        if CLLocationManager.locationServicesEnabled()
        {
            setupLocationManager()
            checkLocationAuthorization()
        }
        else
        {
            print("Please enable location services")
        }
    }
    
    func checkLocationAuthorization()
    {
        switch CLLocationManager.authorizationStatus()
        {
            case.authorizedWhenInUse:
                startTrackingUserLocaiton()
            case.denied:
                print("We need your location, please turn on the permission to access your location")
                break
            case.notDetermined:
            locationManager.requestWhenInUseAuthorization()
            case.restricted:
                print("Something went wrong. Location access restricted")
                break
            case.authorizedAlways:
                break
            default:
                break
        }
    }
    
    @IBAction func centerMyLocation(_ sender: Any)
    {
        startUpdatingLocation = true
        let region = MKCoordinateRegion.init(center: locationManager.location!.coordinate, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = true
    }

    func startTrackingUserLocaiton()
    {
        mapView.showsUserLocation = true
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapView)
    }
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation
    {
        let latitude = mapView.centerCoordinate.latitude
        let longtitude = mapView.centerCoordinate.longitude
        return CLLocation(latitude: latitude, longitude: longtitude)
    }
    
    @IBAction func addMarker(_ sender: Any)
    {
        DispatchQueue.main.async
        {
            self.performMarker(center: self.locationManager.location!.coordinate)
        }
        placedMarker = true
    }
    
    func performMarker(center: CLLocationCoordinate2D)
    {
        self.mapView.showsUserLocation = false
        self.myMarker = MKPointAnnotation()
        self.myMarker?.coordinate = center
        self.myMarker?.title = "MY-MARKER"
        if self.previousMarker != nil
        {
            self.mapView.removeAnnotation(self.previousMarker!)
        }
        self.mapView.addAnnotation(self.myMarker!)
        self.previousMarker = self.myMarker
        self.startUpdatingLocation = false
        let markedRegion = MKCoordinateRegion.init(center: center, latitudinalMeters: 50, longitudinalMeters: 50)
        self.mapView.setRegion(markedRegion, animated: true)
    }
    
    func popUpMarkerDetail(address: String)
    {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MarkerDetailsViewController") as! MarkerDetailsViewController
        vc.modalPresentationStyle = .overFullScreen
        vc.addressString = address
        self.present(vc,animated: true)
    }
    
    func getDirection()
    {
        guard let location = locationManager.location?.coordinate
            else
        {
            return
        }
        let request = createDirectionRequest(from: location)
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions)
        directions.calculate
        {
            [unowned self] (response, error) in
            if error != nil
            {
                print("Error occured while calculating directions: \(error!.localizedDescription) ")
            }
            guard let response = response else
            {
                print("Response is not available")
                return
            }
            for route in response.routes
            {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func createDirectionRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request
    {
        let destinationCoordinate = getCenterLocation(for: mapView).coordinate
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        return request
    }
    
    func resetMapView(withNew directions: MKDirections)
    {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map {$0.cancel()}
        directionsArray.removeFirst()
    }
    
    func showAnnotationsList()
    {
        
    }
    
    func addAnnotations()
    {
//        guard let location = locationManager.location?.coordinate
//            else
//        {
//            return
//        }
//
//        var annotation = MKPointAnnotation()
//        annotation.coordinate = location
    }
    
    @IBAction func drawRoutes(_ sender: Any)
    {
        if myPin.isHidden
        {
            myPin.isHidden = false
        }
        else
        {
            myPin.isHidden = true
            getDirection()
        }
    }
    
    @IBAction func DidTapAddAnnotations(_ sender: Any)
    {
//        if !myPin.isHidden
//        {
//            myPin.isHidden = true
//            addAnnotations()
//            //Do things here
//        }
    }
}

extension ViewController: CLLocationManagerDelegate
{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        guard let location = locations.last else {return}
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        if startUpdatingLocation
        {
            let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
        DispatchQueue.main.async
        {
            if self.placedMarker
            {
                self.mapView.showsUserLocation = true
            }
        }
       
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        checkLocationAuthorization()
    }
}

extension ViewController: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    {
        if(nextRegionChangeIsFromUserInteraction)
        {
            nextRegionChangeIsFromUserInteraction = false;
            startUpdatingLocation = false
        }
        
        let center = getCenterLocation(for: mapView)
        
        guard let previousLocation = self.previousLocation else
        {
            return
        }
        
        guard center.distance(from: previousLocation) > withPreviousDistance else
        {
            return
        }
        
        self.previousLocation = center
        geocoder.reverseGeocodeLocation(center)
        {
            [weak self] (placemarks, error) in
            if error != nil
            {
                print("Failed to geocoding")
            }
            guard let self = self else {return}
            if let _ = error
            {
                return
            }
            guard let placemark = placemarks?.first
                else
            {
                    return
            }
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            
            DispatchQueue.main.async
            {
                self.addressLabel.text = "\(streetNumber) \(streetName)"
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool)
    {
        let view = mapView.subviews.first
        for recognizer in view!.gestureRecognizers!
        {
            if(recognizer.state == UIGestureRecognizer.State.began
                || recognizer.state == UIGestureRecognizer.State.ended)
            {
                self.nextRegionChangeIsFromUserInteraction = true;
                break;
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        let address = CLLocation(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)
        geocoder.reverseGeocodeLocation(address)
        {
            [weak self] (placemarks, error) in
            if error != nil
            {
                print("Failed to geocoding")
            }
            guard let self = self else {return}
            if let _ = error
            {
                return
            }
            guard let placemark = placemarks?.first
                else
            {
                    return
            }
            
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            let subLocality = placemark.subLocality ?? ""
            let subAdminArea = placemark.subAdministrativeArea ?? ""
            let locality = placemark.locality ?? ""
            let country = placemark.country ?? ""
            let address = "\(streetNumber) \(streetName)\n\(subLocality)\n\(subAdminArea)\n\(locality)\n\(country)"
            
            DispatchQueue.main.async
            {
                self.addressLabel.text = "\(streetNumber) \(streetName)"
            }
            
            self.popUpMarkerDetail(address: address)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
    {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .systemBlue
        return renderer
    }
}
