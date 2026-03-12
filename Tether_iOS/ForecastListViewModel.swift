//
//  ForecastListViewModel.swift
//  Tether_iOS
//
//  Created by Synsmyr Forgue on 11/21/23.
//
import CoreLocation
import Foundation
import SwiftUI

class ForecastListViewModel: ObservableObject {
    struct AppError: Identifiable {
        let id = UUID().uuidString
        let errorString: String
    }
    
    @Published var forecasts: [ForecastViewModel] = []
    @Published var appError: AppError? = nil
    @Published var isLoading: Bool = false
    @AppStorage("location") var storageLocation: String = ""
    @Published var location = ""
    @AppStorage("system") var system: Int = 0 {
        didSet {
            for i in 0..<forecasts.count {
                forecasts[i].system = system
            }
        }
    }
    
    init() {
        location = storageLocation
        getWeatherForecast()
    }

    func getWeatherForecast() {
        storageLocation = location
        UIApplication.shared.endEditing()
        if location == "" {
            forecasts = []
        } else {
            isLoading = true
            let apiService = APIService.shared
            CLGeocoder().geocodeAddressString(location) { [weak self] (placemarks, error) in
                guard let self = self else { return }
                if let error = error as? CLError {
                    switch error.code {
                    case .locationUnknown, .geocodeFoundNoResult, .geocodeFoundPartialResult:
                        self.appError = AppError(errorString: NSLocalizedString("Unable to determine location from this text.", comment: ""))
                    case .network:
                        self.appError = AppError(errorString: NSLocalizedString("No network connection.", comment: ""))
                    default:
                        self.appError = AppError(errorString: error.localizedDescription)
                    }
                    self.isLoading = false
                    print(error.localizedDescription)
                    return
                }
                if let lat = placemarks?.first?.location?.coordinate.latitude,
                   let lon = placemarks?.first?.location?.coordinate.longitude {
                    apiService.getJSON(urlString: "https://api.openweathermap.org/data/3.0/onecall?lat=\(lat)&lon=\(lon)&exclude=current,minutely,hourly,alert&appid=b56fb6cb3a06206f5970443f2374877c", dateDecodingStrategy: .secondsSince1970) { [weak self] (result: Result<Forecast, APIService.APIError>) in
                        guard let self = self else { return }
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let forecast):
                                self.isLoading = false
                                self.forecasts = forecast.daily.map { ForecastViewModel(forecast: $0, system: self.system) }
                            case .failure(let apiError):
                                switch apiError {
                                case .error(let errorString):
                                    self.isLoading = false
                                    self.appError = AppError(errorString: errorString)
                                    print(errorString)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
