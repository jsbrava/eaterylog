//
//  LocationManager.swift
//  FoodTracker2
//
//  Created by jim on 26/05/2025.
//


import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // Singleton instance for global access
    static let shared = LocationManager()
    
    // Published properties to be observed by your UI
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // Apple Core Location manager, only used internally
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    // Delegate: update the published location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations.last
//        if let loc = locations.last {
//                print("User location: \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
//            }
    }

    // Delegate: update the published authorization status
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
