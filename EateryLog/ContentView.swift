//
//  ContentView.swift
//  FoodTracker2
//
//  Created by jim on 5/26/25.
//


import SwiftUI

struct ContentView: View {
    @StateObject var restaurantStore = RestaurantStore()
    @StateObject var viewModel = PlacesAutocompleteViewModel()
    @State private var pendingRestaurant: Restaurant? = nil

    var body: some View {
        TabView {
            // Nearby tab
            NavigationStack {
                NearbyRestaurantsView(
                    viewModel: viewModel,
                    restaurantStore: restaurantStore
                ) { suggestion in
                    restaurantStore.buildRestaurant(from: suggestion) { restaurant in
                        pendingRestaurant = restaurant
                    }
                }
                .navigationDestination(item: $pendingRestaurant) { restaurant in
                    RestaurantDetailView(
                        restaurantStore: restaurantStore,
                        restaurantID: restaurant.id,
                        onAddVisit: { visit in
                            saveVisit(for: restaurant.id, visit: visit)
                            pendingRestaurant = nil
                        },
                        onCancel: {
                            pendingRestaurant = nil
                        }
                    )
                }
            }
            .tabItem {
                Image(systemName: "mappin.and.ellipse")
                Text("Nearby")
            }

            // My Restaurants tab
            NavigationStack {
                MyRestaurantsView(restaurantStore: restaurantStore) { restaurant in
                    pendingRestaurant = restaurant
                }
                .navigationDestination(item: $pendingRestaurant) { restaurant in
                    RestaurantDetailView(
                        restaurantStore: restaurantStore,
                        restaurantID: restaurant.id,
                        onAddVisit: { visit in
                            saveVisit(for: restaurant.id, visit: visit)
                            pendingRestaurant = nil
                        },
                        onCancel: {
                            pendingRestaurant = nil
                        }
                    )
                }
            }
            .tabItem {
                Image(systemName: "list.bullet.rectangle")
                Text("My Restaurants")
            }

            // About tab
            NavigationStack {
                AboutView()
            }
            .tabItem {
                Image(systemName: "questionmark.circle")
                Text("About")
            }
        }
    }

    // Always append visit to the up-to-date restaurant in the store!
    private func saveVisit(for restaurantID: String, visit: Visit) {
        if let current = restaurantStore.restaurants.first(where: { $0.id == restaurantID }) {
            var updated = current
            updated.visits.append(visit)
            restaurantStore.addOrUpdateRestaurant(updated)
        }
    }
}
