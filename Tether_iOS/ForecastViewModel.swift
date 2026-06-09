import Foundation

enum UnitSystem: Int {
    case celsius = 0
    case fahrenheit = 1
}

struct ForecastViewModel {
    let forecast: Forecast.Daily
    var system: UnitSystem

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEE, MMM d"
        return df
    }()

    private static let shortDayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return df
    }()

    private static let tempFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.maximumFractionDigits = 0
        return nf
    }()

    private static let percentFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .percent
        nf.maximumFractionDigits = 0
        return nf
    }()

    func convert(temp: Double) -> Double {
        let celsius = temp - 273.15
        return system == .celsius ? celsius : celsius * 9 / 5 + 32
    }

    private func tempString(_ kelvin: Double) -> String {
        Self.tempFormatter.string(for: convert(temp: kelvin)) ?? "0"
    }

    var day: String { Self.dateFormatter.string(from: forecast.dt) }
    var shortDay: String { Self.shortDayFormatter.string(from: forecast.dt) }
    var overview: String { forecast.weather.first?.description.capitalized ?? "" }

    var highTemp: String { "\(tempString(forecast.temp.max))°" }
    var lowTemp: String { "\(tempString(forecast.temp.min))°" }

    var precipPercent: String { Self.percentFormatter.string(for: forecast.pop) ?? "0%" }
    var cloudsValue: Int { forecast.clouds }
    var humidityValue: Int { forecast.humidity }

    var weatherIconURL: URL? {
        guard let icon = forecast.weather.first?.icon else { return nil }
        return URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png")
    }
}
