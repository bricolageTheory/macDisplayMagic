import CoreLocation
import Foundation

/// Completion payload conveying resolved location name and its provenance source type.
public typealias LocationResultBlock = (String, LocationSource) -> Void

/// Service managing macOS CoreLocation updates and reverse-geocoding for display connection events.
public final class LocationService: NSObject, CLLocationManagerDelegate {
    public static let shared = LocationService()

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private var completionBlocks: [LocationResultBlock] = []
    public private(set) var lastKnownLocationName: String = "Location Unknown"
    public private(set) var lastKnownLocationSource: LocationSource = .pending
    public private(set) var lastDiagnosticLog: String = "Initializing Location Service..."

    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        if CLLocationManager.locationServicesEnabled() {
            let status = locationManager.authorizationStatus
            lastDiagnosticLog = "System Location Enabled. Status: \(status.rawValue)"
            if status == .authorizedAlways || status == .authorized {
                locationManager.requestLocation()
            }
        } else {
            lastDiagnosticLog = "System Location Services Disabled globally in macOS System Settings."
        }
    }

    /// Requests macOS Location Services permission.
    public func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Fallback location name generated from system timezone if Wi-Fi positioning is unavailable.
    private var fallbackLocationName: String {
        let tz = TimeZone.current
        let city = tz.identifier.components(separatedBy: "/").last?.replacingOccurrences(of: "_", with: " ") ?? tz.identifier
        let abbr = tz.abbreviation() ?? ""
        return "\(city) (\(abbr))"
    }

    /// Fetches current physical location name or detailed diagnostic explanation if disabled.
    public func fetchCurrentLocationName(completion: @escaping (String) -> Void) {
        fetchCurrentLocationResult { name, _ in
            completion(name)
        }
    }

    /// Fetches current physical location name and provenance source metadata.
    public func fetchCurrentLocationResult(completion: @escaping LocationResultBlock) {
        guard CLLocationManager.locationServicesEnabled() else {
            let msg = "Location Access Disabled (macOS System Location Services Off)"
            lastDiagnosticLog = msg
            completion(msg, .disabled)
            return
        }

        let status = locationManager.authorizationStatus
        lastDiagnosticLog = "Authorization Status: \(status.rawValue)"

        switch status {
        case .denied:
            let msg = "Location Access Disabled (Denied in System Settings > Privacy & Security)"
            completion(msg, .disabled)
            return
        case .restricted:
            let msg = "Location Access Disabled (Restricted by System Policy)"
            completion(msg, .disabled)
            return
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            completion("Location Pending Approval", .pending)
            return
        case .authorizedAlways, .authorized:
            break
        @unknown default:
            completion("Location Access Disabled", .disabled)
            return
        }

        completionBlocks.append(completion)
        locationManager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        lastDiagnosticLog = "Auth Status Changed to: \(status.rawValue)"
        print("[macDisplayMagic] CoreLocation authorization status changed to: \(status.rawValue)")

        if status == .authorizedAlways || status == .authorized {
            locationManager.requestLocation()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            let fallback = fallbackLocationName
            lastDiagnosticLog = "No location coordinates returned. Fallback: \(fallback)"
            notifyCompletions(with: fallback, source: .timezone)
            DispatchQueue.main.async {
                DisplayHistoryStore.shared.updatePendingLocationRecords(with: fallback, source: .timezone)
            }
            return
        }

        lastDiagnosticLog = "Coordinates: Lat \(location.coordinate.latitude), Lon \(location.coordinate.longitude). Geocoding..."

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            let name: String
            let source: LocationSource
            if let placemark = placemarks?.first {
                let locality = placemark.locality ?? placemark.subAdministrativeArea ?? ""
                let adminArea = placemark.administrativeArea ?? placemark.country ?? ""
                
                if !locality.isEmpty && !adminArea.isEmpty {
                    name = "\(locality), \(adminArea)"
                } else if !locality.isEmpty {
                    name = locality
                } else if !adminArea.isEmpty {
                    name = adminArea
                } else {
                    name = "Lat: \(String(format: "%.2f", location.coordinate.latitude)), Lon: \(String(format: "%.2f", location.coordinate.longitude))"
                }
                source = .gps
            } else {
                name = self.fallbackLocationName
                source = .timezone
            }

            self.lastKnownLocationName = name
            self.lastKnownLocationSource = source
            self.lastDiagnosticLog = "Resolved Location: \(name) via \(source.rawValue)"
            self.notifyCompletions(with: name, source: source)

            // Update pending history records with actual location name and source
            DispatchQueue.main.async {
                DisplayHistoryStore.shared.updatePendingLocationRecords(with: name, source: source)
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let fallback = (lastKnownLocationName != "Location Unknown") ? lastKnownLocationName : fallbackLocationName
        let source: LocationSource = (lastKnownLocationName != "Location Unknown") ? lastKnownLocationSource : .timezone
        lastDiagnosticLog = "CoreLocation Error: \(error.localizedDescription). Fallback to: \(fallback)"
        print("[macDisplayMagic] CoreLocation error: \(error.localizedDescription). Fallback: \(fallback)")
        notifyCompletions(with: fallback, source: source)
        DispatchQueue.main.async {
            DisplayHistoryStore.shared.updatePendingLocationRecords(with: fallback, source: source)
        }
    }

    private func notifyCompletions(with locationName: String, source: LocationSource) {
        let blocks = completionBlocks
        completionBlocks.removeAll()
        DispatchQueue.main.async {
            for block in blocks {
                block(locationName, source)
            }
        }
    }
}
