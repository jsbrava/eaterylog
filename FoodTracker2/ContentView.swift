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
            VStack {
                NearbyRestaurantsView(viewModel: viewModel) { suggestion in
                    // ASYNC: Add to store, then set selection in the completion
                    restaurantStore.addRestaurantIfNeeded(from: suggestion) { restaurant in
                        selectedRestaurant = restaurant
                    }
                }
            }
            .navigationTitle("Select Restaurant")
            .navigationDestination(item: $selectedRestaurant) { restaurant in
                RestaurantDetailView(restaurantStore: restaurantStore, restaurant: restaurant)
            }
        }
    }
}
