//
//  ForecastViewModel.swift
//  Tether_iOS
//
//  Created by Synsmyr Forgue on 11/21/23.
//

import Foundation

struct ForecastViewModel {
    let forecast: Forecast.Daily
    var system: Int

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = " E MMM, d"
        return df
    }()

    private static let numberFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.maximumFractionDigits = 0
        return nf
    }()

    private static let percentFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .percent
        return nf
    }()

    func convert(temp: Double) -> Double {
        let celsius = temp - 273.15
        return system == 0 ? celsius : celsius * 9 / 5 + 32
    }

    var day: String {
        Self.dateFormatter.string(from: forecast.dt)
    }

    var overview: String {
        forecast.weather.first?.description.capitalized ?? ""
    }

    var high: String {
        "H: \(Self.numberFormatter.string(for: convert(temp: forecast.temp.max)) ?? "0")°"
    }

    var low: String {
        "L: \(Self.numberFormatter.string(for: convert(temp: forecast.temp.min)) ?? "0")°"
    }

    var pop: String {
        "💧 \(Self.percentFormatter.string(for: forecast.pop) ?? "0%")"
    }

    var clouds: String {
        "☁️ \(forecast.clouds)%"
    }

    var humidity: String {
        "Humidity \(forecast.humidity)%"
    }

    var weatherIconURL: URL? {
        guard let icon = forecast.weather.first?.icon else { return nil }
        return URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png")
    }
}
