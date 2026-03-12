# Tether Weather

A SwiftUI iOS app that shows a 7-day weather forecast for any location using the [OpenWeatherMap One Call API 3.0](https://openweathermap.org/api/one-call-3). Built as a first step into iOS development—focused on networking, API integration, and a simple, responsive UI.

---

## Features

- **7-day forecast** — Daily high/low, conditions, humidity, cloud cover, and precipitation chance
- **Location search** — Enter a city or place; results are geocoded and used to fetch weather
- **°C / °F toggle** — Switch between Celsius and Fahrenheit; preference is saved
- **Last location** — Your last searched location is remembered and loaded on launch
- **Weather icons** — Condition icons loaded from OpenWeatherMap
- **Error handling** — Clear messages for geocoding failures, network issues, and missing API key

---

## Screenshots

_Add screenshots of the app here (e.g. main screen, forecast list, dark mode)._

---

## Tech Stack

| Layer        | Technology |
|-------------|------------|
| **UI**      | SwiftUI (iOS 17+) |
| **Architecture** | MVVM |
| **Networking**   | `URLSession`, OpenWeatherMap One Call API 3.0 |
| **Geocoding**    | `CLGeocoder` (Core Location) |
| **Persistence**  | `@AppStorage` for location and unit preference |
| **Images**       | [SDWebImageSwiftUI](https://github.com/SDWebImage/SDWebImageSwiftUI) for async icon loading |

---

## Requirements

- **Xcode** 15+
- **iOS** 17.0+
- **OpenWeatherMap API key** — [Sign up](https://openweathermap.org/api) and create a key (One Call API 3.0)

---

## Installation

### 1. Clone the repo

```bash
git clone https://github.com/SynsmyrF2001/Tether-Weather-App.git
cd Tether-Weather-App
```

### 2. Add your OpenWeatherMap API key

The app reads the API key from a config file that is **not** committed to the repo.

1. Copy the example config:
   ```bash
   cp ApiKeys.xcconfig.example ApiKeys.xcconfig
   ```
2. Open `ApiKeys.xcconfig` and replace `YOUR_OPENWEATHERMAP_API_KEY` with your key from [OpenWeatherMap](https://openweathermap.org/api).

Do not commit `ApiKeys.xcconfig`; it is listed in `.gitignore`.

### 3. Open and run in Xcode

1. Open `Tether_iOS.xcodeproj` in Xcode.
2. Select a simulator or device and press **⌘R** to build and run.

Dependencies (SDWebImageSwiftUI) are resolved via Swift Package Manager when you open the project.

---

## Project structure

```
Tether_iOS/
├── Tether_iOSApp.swift          # App entry point
├── ContentView.swift           # Main screen: picker, search, forecast list
├── ForecastListViewModel.swift # Geocoding, API calls, persisted preferences
├── ForecastViewModel.swift     # Per-day display logic, unit conversion
├── Forecast.swift              # Codable models for API response
├── API Service.swift           # Generic JSON fetch with URLSession
├── UIApplication+Extension.swift
├── Assets.xcassets
└── Preview Content/
```

Config at repo root:

- `ApiKeys.xcconfig` — Your local API key (gitignored; create from `ApiKeys.xcconfig.example`).
- `ApiKeys.xcconfig.example` — Template showing required keys.

---

## Architecture

- **MVVM** — `ForecastListViewModel` holds state and talks to `APIService` and `CLGeocoder`; views observe via `@StateObject` / `@Published`.
- **API** — One Call API 3.0 returns 7-day `daily` data; `Forecast` and `Forecast.Daily` map the JSON.
- **Units** — API uses Kelvin; `ForecastViewModel` converts to °C or °F based on the user’s choice stored in `@AppStorage`.

---

## License

This project is for portfolio and learning purposes. OpenWeatherMap data is subject to [OpenWeatherMap’s terms and conditions](https://openweathermap.org/terms).
