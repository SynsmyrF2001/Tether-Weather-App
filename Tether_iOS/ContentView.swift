import SDWebImageSwiftUI
import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ForecastListViewModel()
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color.blue.opacity(0.07)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                        .padding(.horizontal)
                        .padding(.bottom, 10)

                    if vm.forecasts.isEmpty && !vm.isLoading {
                        emptyState
                    } else {
                        forecastList
                    }
                }
            }
            .navigationTitle("Tether Weather")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    unitPicker
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { searchFocused = false }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { vm.appError != nil },
                set: { if !$0 { vm.appError = nil } }
            ), presenting: vm.appError) { _ in
                Button("OK", role: .cancel) { vm.appError = nil }
            } message: { error in
                Text(error.errorString)
            }
        }
        .overlay {
            if vm.isLoading { loadingOverlay }
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                TextField("Search location", text: $vm.location)
                    .focused($searchFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .onSubmit {
                        searchFocused = false
                        Task { await vm.getWeatherForecast() }
                    }
                if !vm.location.isEmpty {
                    Button {
                        vm.location = ""
                        vm.forecasts = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))

            Button {
                searchFocused = false
                Task { await vm.getWeatherForecast() }
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
            }
            .tint(.blue)

            Button {
                vm.requestCurrentLocation()
            } label: {
                Image(systemName: "location.circle.fill")
                    .font(.title2)
            }
            .tint(vm.locationPermission == .denied ? .gray : .blue)
        }
    }

    private var unitPicker: some View {
        Picker("Unit", selection: Binding(
            get: { vm.unitSystem },
            set: { vm.unitSystem = $0 }
        )) {
            Text("°C").tag(UnitSystem.celsius)
            Text("°F").tag(UnitSystem.fahrenheit)
        }
        .pickerStyle(.segmented)
        .frame(width: 90)
    }

    private var forecastList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(vm.forecasts, id: \.day) { day in
                    ForecastRow(day: day)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue.opacity(0.6))
            Text("Search for a location\nor tap the arrow to use GPS")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
        .frame(maxHeight: .infinity)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            ProgressView("Tapping in…")
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 10)
        }
    }
}

// MARK: - Forecast Row

struct ForecastRow: View {
    let day: ForecastViewModel

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                WebImage(url: day.weatherIconURL)
                    .resizable()
                    .placeholder {
                        Image(systemName: "cloud.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.blue.opacity(0.4))
                    }
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                Text(day.shortDay)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 62)

            VStack(alignment: .leading, spacing: 5) {
                Text(day.overview)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(day.day)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Label(day.precipPercent, systemImage: "drop.fill")
                        .foregroundStyle(.blue)
                    Label("\(day.cloudsValue)%", systemImage: "cloud.fill")
                        .foregroundStyle(.secondary)
                    Label("\(day.humidityValue)%", systemImage: "humidity")
                        .foregroundStyle(.teal)
                }
                .font(.caption)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(day.highTemp)
                    .font(.title3.weight(.bold))
                Text(day.lowTemp)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ContentView()
}
