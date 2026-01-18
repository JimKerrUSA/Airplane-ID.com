//
//  LocationServices.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/18/26.
//
//  Location services manager for map functionality.
//  Handles CLLocationManager authorization and updates.
//

import Foundation
import CoreLocation

// MARK: - Location Manager
/// Singleton manager for device location services
/// Used by MapsPage to show user location and enable location-based features
@MainActor
@Observable
final class LocationManager: NSObject {
    static let shared = LocationManager()

    // MARK: - Properties
    private let locationManager = CLLocationManager()

    /// Current device location (nil if not yet determined or denied)
    var currentLocation: CLLocationCoordinate2D?

    /// Current authorization status
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// Whether location services are authorized for use
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    /// Whether location services are denied or restricted
    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    /// Human-readable status for debugging
    var statusDescription: String {
        switch authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }

    // MARK: - Initialization
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Public Methods

    /// Request location authorization (when in use)
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Start receiving location updates
    func startUpdatingLocation() {
        guard isAuthorized else {
            #if DEBUG
            print("LocationManager: Cannot start updates - not authorized (\(statusDescription))")
            #endif
            return
        }
        locationManager.startUpdatingLocation()
    }

    /// Stop receiving location updates
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    /// Request a single location update
    func requestLocation() {
        guard isAuthorized else {
            requestAuthorization()
            return
        }
        locationManager.requestLocation()
    }

    /// Check current authorization and request if not determined
    func checkAndRequestAuthorization() {
        authorizationStatus = locationManager.authorizationStatus
        if authorizationStatus == .notDetermined {
            requestAuthorization()
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location.coordinate
            #if DEBUG
            print("LocationManager: Updated location to \(location.coordinate.latitude), \(location.coordinate.longitude)")
            #endif
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            #if DEBUG
            print("LocationManager: Authorization changed to \(self.statusDescription)")
            #endif

            // Start updates if just authorized
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if DEBUG
        Task { @MainActor in
            print("LocationManager: Error - \(error.localizedDescription)")
        }
        #endif
    }
}
