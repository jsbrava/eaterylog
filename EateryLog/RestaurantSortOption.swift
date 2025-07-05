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
    @State private var sortOption: RestaurantSortOption = .distance
    @State private var selectedRestaurant: Restaurant? = nil

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

            List(sortedRestaurants) { restaurant in
                Button {
                    selectedRestaurant = restaurant
                } label: {
                    HStack {
                        Text(restaurant.name)
                        Spacer()
                        if sortOption == .distance, let userLocation = locationManager.location {
                            Text(restaurant.formattedDistance(from: userLocation))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
        .navigationTitle("My Restaurants")
        .navigationDestination(item: $selectedRestaurant) { restaurant in
            RestaurantDetailView(restaurantStore: restaurantStore, restaurant: restaurant)
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