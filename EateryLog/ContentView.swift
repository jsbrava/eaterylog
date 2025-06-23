//
//  ContentView.swift
//  FoodTracker2
//
//  Created by jim on 5/26/25.
//


import SwiftUI

struct ContentView: View {
    @State private var selectedRestaurant: Restaurant? = nil
    @StateObject var restaurantStore = RestaurantStore()
    @StateObject var viewModel = PlacesAutocompleteViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Pass restaurantStore as a parameter
                NearbyRestaurantsView(viewModel: viewModel, restaurantStore: restaurantStore) { suggestion in
                    restaurantStore.addRestaurantIfNeeded(from: suggestion) { restaurant in
                        selectedRestaurant = restaurant
                    }
                }
            }
            .navigationDestination(item: $selectedRestaurant) { restaurant in
                RestaurantDetailView(restaurantStore: restaurantStore, restaurant: restaurant)
            }
        }
    }
}
