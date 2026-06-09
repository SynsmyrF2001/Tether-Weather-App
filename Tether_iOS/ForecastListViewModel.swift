import CoreLocation
import Foundation
import SwiftUI

@MainActor
final class ForecastListViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    struct AppError: Identifiable {
        let id = UUID().uuidString
        let errorString: String
    }

    @Published var forecasts: [ForecastViewModel] = []
    @Published var appError: AppError? = nil
    @Published var isLoading = false
    @Published var locationPermission: CLAuthorizationStatus = .notDetermined

    @AppStorage("location") var storageLocation: String = ""
    @Published var location = ""

    @AppStorage("system") private var systemRaw: Int = UnitSystem.celsius.rawValue {
        didSet {
            for i in 0..<forecasts.count {
                forecasts[i].system = unitSystem
            }
        }
    }

    var unitSystem: UnitSystem {
        get { UnitSystem(rawValue: systemRaw) ?? .celsius }
        set { systemRaw = newValue.rawValue }
    }

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationPermission = locationManager.authorizationStatus
        location = storageLocation
        Task { await getWeatherForecast() }
    }

    func getWeatherForecast() async {
        storageLocation = location
        guard !location.isEmpty else { forecasts = []; return }
        isLoading = true
        defer { isLoading = false }
        do {
            let coord = try await geocodeAddress(location)
            try await fetchWeather(at: coord)
        } catch let clError as CLError {
            appError = AppError(errorString: geocoderErrorMessage(clError))
        } catch {
            appError = AppError(errorString: error.localizedDescription)
        }
    }

    func requestCurrentLocation() {
        switch locationPermission {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isLoading = true
            locationManager.requestLocation()
        case .denied, .restricted:
            appError = AppError(errorString: "Location access is denied. Enable it in Settings > Privacy > Location Services.")
        @unknown default:
            break
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.locationPermission = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.isLoading = true
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let clLocation = locations.first else { return }
        Task { @MainActor in
            defer { self.isLoading = false }
            do {
                let placemarks = try await self.reverseGeocode(clLocation)
                if let name = placemarks.first?.locality ?? placemarks.first?.name {
                    self.location = name
                    self.storageLocation = name
                }
                try await self.fetchWeather(at: clLocation.coordinate)
            } catch {
                self.appError = AppError(errorString: error.localizedDescription)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.appError = AppError(errorString: error.localizedDescription)
            self.isLoading = false
        }
    }

    // MARK: - Private

    private func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            CLGeocoder().geocodeAddressString(address) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let coord = placemarks?.first?.location?.coordinate {
                    continuation.resume(returning: coord)
                } else {
                    continuation.resume(throwing: CLError(.geocodeFoundNoResult))
                }
            }
        }
    }

    private func reverseGeocode(_ location: CLLocation) async throws -> [CLPlacemark] {
        try await withCheckedThrowingContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: placemarks ?? [])
                }
            }
        }
    }

    private func fetchWeather(at coord: CLLocationCoordinate2D) async throws {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OpenWeatherMapAPIKey") as? String,
              !apiKey.isEmpty else {
            appError = AppError(errorString: "OpenWeatherMap API key is missing. Add it in ApiKeys.xcconfig.")
            return
        }
        let urlString = "https://api.openweathermap.org/data/3.0/onecall?lat=\(coord.latitude)&lon=\(coord.longitude)&exclude=current,minutely,hourly,alert&appid=\(apiKey)"
        let forecast: Forecast = try await APIService.shared.getJSON(urlString: urlString, dateDecodingStrategy: .secondsSince1970)
        forecasts = forecast.daily.map { ForecastViewModel(forecast: $0, system: unitSystem) }
    }

    private func geocoderErrorMessage(_ error: CLError) -> String {
        switch error.code {
        case .locationUnknown, .geocodeFoundNoResult, .geocodeFoundPartialResult:
            return "Unable to determine location from this text."
        case .network:
            return "No network connection."
        default:
            return error.localizedDescription
        }
    }
}
