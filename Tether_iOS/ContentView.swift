//
//  ContentView.swift
//  Tether_iOS
//
//  Created by Synsmyr Forgue on 11/20/23.
//

import SDWebImageSwiftUI
import SwiftUI

struct ContentView: View {
    @StateObject private var forecastListVM = ForecastListViewModel()

    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    Picker(selection: $forecastListVM.system, label: Text("System")) {
                        Text("°C").tag(0)
                        Text("°F").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                    .padding(.vertical)

                    HStack {
                        TextField("Enter Location", text: $forecastListVM.location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .overlay(
                                Button(action: {
                                    forecastListVM.location = ""
                                    forecastListVM.getWeatherForecast()
                                }) {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal),
                                alignment: .trailing
                            )
                            .onSubmit {
                                forecastListVM.getWeatherForecast()
                            }

                        Button {
                            forecastListVM.getWeatherForecast()
                        } label: {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.title3)
                        }
                    }

                    List(forecastListVM.forecasts, id: \.day) { day in
                        VStack(alignment: .leading) {
                            Text(day.day)
                                .fontWeight(.bold)
                            HStack(alignment: .center) {
                                WebImage(url: day.weatherIconURL)
                                    .resizable()
                                    .placeholder {
                                        Image(systemName: "hourglass")
                                    }
                                    .scaledToFit()
                                    .frame(width: 75)
                                VStack(alignment: .leading) {
                                    Text(day.overview)
                                        .font(.title2)
                                    HStack {
                                        Text(day.high)
                                        Text(day.low)
                                    }
                                    HStack {
                                        Text(day.clouds)
                                        Text(day.pop)
                                    }
                                    Text(day.humidity)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                .padding(.horizontal)
                .navigationTitle("Tether Weather")
                .alert("Error", isPresented: Binding(
                    get: { forecastListVM.appError != nil },
                    set: { if !$0 { forecastListVM.appError = nil } }
                ), presenting: forecastListVM.appError) { _ in
                    Button("OK", role: .cancel) { forecastListVM.appError = nil }
                } message: { error in
                    Text("\(error.errorString)\nPlease try again later")
                }
            }

            if forecastListVM.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Tapping in")
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemBackground))
                        )
                        .shadow(radius: 10)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
