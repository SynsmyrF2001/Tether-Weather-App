//
//  Forecast.swift
//  Tether_iOS
//
//  Created by Ferguson Sam Forgue on 11/20/23.
//

import Foundation

struct Forecast: Codable{
    struct Daily: Codable {
        let dt: Date
        struct Temp: Codable {
            let min: Double
            let max: Double
        }
        let temp: Temp
        let humidity: Int
        struct Weather: Codable{
            let id: Int
            let description: String
            let icon: String
        }
        let weather: [Weather]
        let clouds: Int
        let pop: Double
    }
    let daily: [Daily]
}
