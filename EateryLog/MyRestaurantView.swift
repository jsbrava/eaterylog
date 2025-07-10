//
//  RestaurantSortOption.swift
//  EateryLog
//
//  Created by jim on 7/5/25.
//


import SwiftUI
import CoreLocation

enum RestaurantSortOption: String, CaseIterable, Identifiable {
    case distance = "Distance"
    case alphabetical = "A–Z"
    var id: String { self.rawValue }
}

struct MyRestaurantsView: View {
    @ObservedObject var restaurantStore: RestaurantStore
    @ObservedObject var locationManager = LocationManager.shared
    var onSelect: (Restaurant) -> Void       // <-- NEW: closure for item taps
    @State private var sortOption: RestaurantSortOption = .distance

    var sortedRestaurants: [Restaurant] {
        let restaurants = restaurantStore.restaurants
        switch sortOption {
        case .distance:
            guard let userLocation = locationManager.location else { return restaurants }
            return restaurants.sorted {
                $0.distance(from: userLocation) < $1.distance(from: userLocation)
            }
        case .alphabetical:
            return restaurants.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    var body: some View {
        VStack {
            Picker("Sort by", selection: $sortOption) {
                ForEach(RestaurantSortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List {
                ForEach(sortedRestaurants) { restaurant in
                    Button {
                        onSelect(restaurant)   // <-- Call the closure
                    } label: {
                        HStack {
                            Text(restaurant.name)
                                .fontWeight(restaurant.visits.isEmpty ? .regular : .bold)
                                .foregroundColor(.blue)
                            Spacer()
                            if sortOption == .distance, let userLocation = locationManager.location {
                                Text(restaurant.formattedDistance(from: userLocation))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteRestaurant)
            }
            .listStyle(.inset)
        }
        .navigationTitle("My Restaurants")
        // <-- Remove .navigationDestination here!
    }

    private func deleteRestaurant(at offsets: IndexSet) {
        for index in offsets {
            let restaurant = sortedRestaurants[index]
            if let actualIndex = restaurantStore.restaurants.firstIndex(where: { $0.id == restaurant.id }) {
                restaurantStore.restaurants.remove(at: actualIndex)
                restaurantStore.save()
            }
        }
    }
}

// MARK: - Distance Helper Extensions

extension Restaurant {
    func distance(from location: CLLocation) -> CLLocationDistance {
        let restaurantLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        return restaurantLocation.distance(from: location)
    }

    func formattedDistance(from location: CLLocation) -> String {
        let meters = distance(from: location)
        let miles = meters / 1609.344
        if miles >= 0.1 {
            return String(format: "%.1f mi", miles)
        } else {
            // Under 0.1 mile, show in feet
            let feet = meters * 3.28084
            return String(format: "%.0f ft", feet)
        }
    }
}
