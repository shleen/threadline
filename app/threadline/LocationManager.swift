//
//  LocationManager.swift
//  threadline
//
//  Created by sheline on 3/21/25.
//

import SwiftUI
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var errorMessage: String?

    // Array to store all completion handlers
    private var locationCallbacks: [(CLLocation) -> Void] = []

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    func requestLocation(completion: @escaping (CLLocation) -> Void) {
        // If we already have a location, call completion immediately
        if let currentLocation = location {
            completion(currentLocation)
            return
        }

        // Otherwise, store the callback to be called when we get a location
        locationCallbacks.append(completion)
        locationManager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location

        // Call all registered callbacks with the new location
        locationCallbacks.forEach { callback in
            callback(location)
        }

        // Clear the callbacks after they've been called
        locationCallbacks.removeAll()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
    }
}
