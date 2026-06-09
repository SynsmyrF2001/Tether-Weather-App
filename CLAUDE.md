# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tether Weather is an iOS weather app built with SwiftUI. It uses the OpenWeatherMap One Call API 3.0 to display a 7-day forecast for a user-entered location. The app supports Celsius/Fahrenheit toggling, persists the last searched location via `@AppStorage`, and can fetch weather for the device's current GPS location.

## Building & Running

Open `Tether_iOS.xcodeproj` in Xcode and build/run with `Cmd+R`. There is no package manager CLI — SPM dependencies (SDWebImageSwiftUI) are managed by Xcode directly.

To run tests: `Cmd+U` in Xcode, or via CLI:
```
xcodebuild test -project "Tether_iOS.xcodeproj" -scheme Tether_iOS -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Architecture

The app uses MVVM with SwiftUI:

- **`Forecast.swift`** — Codable model mapping the OpenWeatherMap API JSON response (`daily[]` array with `dt`, `temp`, `humidity`, `weather`, `clouds`, `pop`).
- **`ForecastViewModel.swift`** — Per-day view model wrapping `Forecast.Daily`. Declares the `UnitSystem` enum (`.celsius`/`.fahrenheit`). Handles Kelvin → °C/°F conversion and formats display strings. Uses `static let` formatters.
- **`ForecastListViewModel.swift`** — `@MainActor ObservableObject` driving `ContentView`. Uses `async/await` with `CLGeocoder` (wrapped in `withCheckedThrowingContinuation`) to resolve typed locations, `CLLocationManager` for GPS, and `APIService` for weather data. Persists location and unit system via `@AppStorage`.
- **`API Service.swift`** — Singleton `APIService.shared` with a generic `getJSON<T: Decodable>` async-throws method using `URLSession`.
- **`ContentView.swift`** — Single-screen UI with an inline nav title, unit picker in the toolbar, a search bar with GPS button, and a `LazyVStack` forecast list. Keyboard dismiss uses `@FocusState`. Uses `SDWebImageSwiftUI`'s `WebImage` for icon loading. Forecast cards use `.regularMaterial` background.
- **`Item.swift`** — Unused SwiftData `@Model` stub from the Xcode template. Safe to delete from the Xcode project.
- **`UIApplication+Extension.swift`** — Unused `endEditing()` helper (replaced by `@FocusState`). Safe to delete from the Xcode project.

## Key Notes

- **API key**: The OpenWeatherMap API key is not in source. It is read from `OpenWeatherMapAPIKey` in the app's Info.plist, which is set via `ApiKeys.xcconfig` (gitignored). Copy `ApiKeys.xcconfig.example` to `ApiKeys.xcconfig` and add your key. The app targets the OpenWeatherMap One Call API 3.0 endpoint.
- **GPS / location permission**: `NSLocationWhenInUseUsageDescription` must be set. In Xcode, go to the target → Info tab and add this key with a description string, or add `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = <description>` to the xcconfig.
- Temperature conversion happens in `ForecastViewModel.convert(temp:)`: API values are in Kelvin, subtract 273.15 to get Celsius.
- `unitSystem` (`UnitSystem` enum) is stored as a raw `Int` via `@AppStorage("system")` in `ForecastListViewModel` and propagated to all `ForecastViewModel` items on change.
- `weatherIconURL` returns `URL?` — SDWebImageSwiftUI's `WebImage` handles optional URLs natively.

## Refinements Applied

### Bug Fixes (prior session)
- **`appError` made `@Published`** — was not reactive, so `.alert` binding never fired.
- **Kelvin constant**: fixed `273.5` → `273.15`.
- **Force-unwrap URL removed**: `weatherIconURL` is now `URL?`.
- **Unsafe array access removed**: `forecast.weather[0]` → `forecast.weather.first?`.
- **HTTP status codes**: `APIService` fails with a descriptive error for non-2xx responses.

### Modernisation (prior session)
- `NavigationView` → `NavigationStack`, `onCommit:` → `.onSubmit {}`, modern `.alert` API, `#Preview` macro, static formatters, typo fix (`getWeatherFoecast` → `getWeatherForecast`).

### Refinement Pass (current)
- **`async/await`**: `APIService.getJSON` is now `async throws`. `ForecastListViewModel` is `@MainActor` with `async` methods; all `DispatchQueue.main.async` and `[weak self]` guards removed.
- **GPS**: `ForecastListViewModel` conforms to `CLLocationManagerDelegate`. `requestCurrentLocation()` requests device location; on success, reverse-geocodes to a city name and fetches the forecast.
- **`UnitSystem` enum**: replaces the raw `Int` (0/1) throughout `ForecastViewModel` and `ForecastListViewModel`.
- **`@FocusState`**: replaces the `UIApplication.shared.endEditing()` hack for keyboard dismissal.
- **UI redesign**: subtle gradient background, card-style `ForecastRow` with `.regularMaterial`, `LazyVStack` instead of `List`, short-day + date label, H/L temps with bold hierarchy, stat labels using SF Symbols (drop, cloud, humidity).
- **Dead code**: SwiftData `ModelContainer` removed from `Tether_iOSApp.swift`; `Item.swift` and `UIApplication+Extension.swift` are now unused (remove from Xcode project when convenient).
