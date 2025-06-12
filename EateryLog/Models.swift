//
//  Models.swift
//  FoodTracker2
//
//  Created by jim on 25/05/2025.
//

import Foundation
import CoreLocation

struct Restaurant: Identifiable, Codable, Equatable, Hashable {
    var id: String { placeID }
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let placeID: String
    var visits: [Visit]
}

struct Visit: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let date: Date
    var dishes: [Dish]

    // Add this explicit initializer
    init(id: UUID = UUID(), date: Date, dishes: [Dish]) {
        self.id = id
        self.date = date
        self.dishes = dishes
    }
}

struct Dish: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let orderedBy: String
    let notes: String
    let rating: Int

    // Explicit initializer with default UUID
    init(id: UUID = UUID(), name: String, orderedBy: String, notes: String, rating: Int) {
        self.id = id
        self.name = name
        self.orderedBy = orderedBy
        self.notes = notes
        self.rating = rating
    }
}
struct PlaceSuggestion: Identifiable {
    let id = UUID()
    let description: String
    let placeID: String
}
extension Restaurant {
    func distance(from userLocation: CLLocation?) -> CLLocationDistance? {
        guard let userLocation = userLocation else { return nil }
        let restaurantLocation = CLLocation(latitude: latitude, longitude: longitude)
        return userLocation.distance(from: restaurantLocation)
    }
}
