//
//  Restaurant+Distance.swift
//  EateryLog
//
//  Created by jim on 7/23/25.
//

import Foundation
import CoreLocation

extension Restaurant {
    func distance(from location: CLLocation) -> CLLocationDistance? {
        let restaurantLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        return restaurantLocation.distance(from: location)
    }

    func formattedDistance(from location: CLLocation) -> String {
        guard let meters = self.distance(from: location) else { return "" }
        let miles = meters / 1609.344
        if miles >= 0.1 {
            return String(format: "%.1f mi", miles)
        } else {
            let feet = meters * 3.28084
            return String(format: "%.0f ft", feet)
        }
    }
}
