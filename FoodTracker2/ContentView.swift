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
        NavigationView {
            VStack {
                NearbyRestaurantsView(viewModel: viewModel) { suggestion in
                    restaurantStore.addRestaurantIfNeeded(from: suggestion) { restaurant in
                        selectedRestaurant = restaurant
                    }
                }
                // Invisible NavigationLink for programmatic navigation
                NavigationLink(
                    destination: {
                        if let restaurant = selectedRestaurant {
                            AnyView(RestaurantDetailView(restaurant: restaurant))
                        } else {
                            AnyView(EmptyView())
                        }
                    }(),
                    isActive: Binding(
                        get: { selectedRestaurant != nil },
                        set: { active in if !active { selectedRestaurant = nil } }
                    )
                ) {
                    EmptyView()
                }
            }
            .navigationTitle("Select Restaurant")
        }
    }
}
