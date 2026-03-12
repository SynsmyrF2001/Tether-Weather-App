# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tether Weather is an iOS weather app built with SwiftUI. It uses the OpenWeatherMap One Call API 3.0 to display a 7-day forecast for a user-entered location. The app supports Celsius/Fahrenheit toggling and persists the last searched location via `@AppStorage`.

## Building & Running

Open `Tether_iOS.xcodeproj` in Xcode and build/run with `Cmd+R`. There is no package manager CLI — SPM dependencies (SDWebImageSwiftUI) are managed by Xcode directly.

To run tests: `Cmd+U` in Xcode, or via CLI:
```
xcodebuild test -project "Tether_iOS.xcodeproj" -scheme Tether_iOS -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Architecture

The app uses MVVM with SwiftUI:

- **`Forecast.swift`** — Codable model mapping the OpenWeatherMap API JSON response (`daily[]` array with `dt`, `temp`, `humidity`, `weather`, `clouds`, `pop`).
- **`ForecastViewModel.swift`** — Per-day view model wrapping `Forecast.Daily`. Handles unit conversion from Kelvin (API returns Kelvin) to °C or °F, and formats display strings for high/low/clouds/pop/humidity/icon URL.
- **`ForecastListViewModel.swift`** — `ObservableObject` driving `ContentView`. Uses `CLGeocoder` to resolve the typed location string to lat/lon, then calls `APIService`. Persists location and unit system via `@AppStorage`.
- **`API Service.swift`** — Singleton `APIService.shared` with a generic `getJSON<T: Decodable>` method using `URLSession`. Configurable `dateDecodingStrategy` and `keyDecodingStrategy`.
- **`ContentView.swift`** — Single-screen UI with a segmented C°/F° picker, location text field, forecast list, and a loading overlay. Uses `SDWebImageSwiftUI`'s `WebImage` for icon loading.
- **`UIApplication+Extension.swift`** — Adds `endEditing()` to dismiss the keyboard on search.
- **`Item.swift`** — SwiftData `@Model` stub from the Xcode template; not used by the weather feature.

## Key Notes

- The API key is hardcoded in `ForecastListViewModel.swift` in the `getWeatherForecast()` call. It targets the OpenWeatherMap One Call API 3.0 endpoint.
- Temperature conversion happens in `ForecastViewModel.convert(temp:)`: API values are in Kelvin, subtract 273.15 to get Celsius.
- The `system` property (0 = Celsius, 1 = Fahrenheit) is stored via `@AppStorage("system")` and propagated to all `ForecastViewModel` items on change.
- `weatherIconURL` returns `URL?` — SDWebImageSwiftUI's `WebImage` handles optional URLs natively.
- `SwiftData` / `ModelContainer` is set up in `Tether_iOSApp.swift` but the `Item` model is unused — leftover from the Xcode template.

## Refinements Applied

### Bug Fixes
- **`appError` made `@Published`** — was not reactive, so `.alert` binding never fired.
- **Threading**: all UI state mutations from the `APIService` completion are wrapped in `DispatchQueue.main.async`; geocoder error path now returns early to prevent falling through to the coordinate check.
- **Retain cycles**: added `[weak self]` + `guard let self` to both async closures in `ForecastListViewModel`.
- **Kelvin constant**: fixed `273.5` → `273.15` in `ForecastViewModel.convert(temp:)`.
- **Force-unwrap URL removed**: `weatherIconURL` is now `URL?`, built with `forecast.weather.first?.icon`.
- **Unsafe array access removed**: all `forecast.weather[0]` replaced with `forecast.weather.first?` with safe fallbacks.
- **HTTP status codes**: `APIService` now fails with a descriptive error for non-2xx responses before attempting to decode.

### Modernisation & Polish
- **`NavigationView` → `NavigationStack`** (iOS 16+).
- **`onCommit:` → `.onSubmit {}`** (deprecated since iOS 15).
- **`.pickerStyle(SegmentedPickerStyle())` → `.pickerStyle(.segmented)`**.
- **`.listStyle(PlainListStyle())` → `.listStyle(.plain)`**.
- **`Alert(title:message:)` → `alert(_:isPresented:presenting:actions:message:)`** (modern non-deprecated form).
- **Loading overlay**: `Color(.white).opacity(0.3)` → `Color.black.opacity(0.3)` to work correctly in dark mode.
- **`PreviewProvider` struct → `#Preview` macro**.
- **Static formatters**: changed from computed `var` (new instance each access) to `static let` with closure initialiser in `ForecastViewModel`.
- **Typo**: `getWeatherFoecast` renamed to `getWeatherForecast` throughout.
