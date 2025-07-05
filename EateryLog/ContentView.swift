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
    // If you want to handle selection for MyRestaurantsView as well, you can add a second selectedRestaurant state.

    var body: some View {
        TabView {
            // Nearby tab
            NavigationStack {
                NearbyRestaurantsView(
                    viewModel: viewModel,
                    restaurantStore: restaurantStore
                ) { suggestion in
                    restaurantStore.addRestaurantIfNeeded(from: suggestion) { restaurant in
                        selectedRestaurant = restaurant
                    }
                }
                .navigationDestination(item: $selectedRestaurant) { restaurant in
                    RestaurantDetailView(restaurantStore: restaurantStore, restaurant: restaurant)
                }
            }
            .tabItem {
                Image(systemName: "mappin.and.ellipse")
                Text("Nearby")
            }

            // My Restaurants tab
            NavigationStack {
                MyRestaurantsView(restaurantStore: restaurantStore)
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
}
