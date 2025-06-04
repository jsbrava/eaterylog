//
//  ImHereView.swift
//  FoodTracker2
//
//  Created by jim on 26/05/2025.
//


import SwiftUI
import CoreLocation

struct ImHereView: View {
    @EnvironmentObject var store: RestaurantStore
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var manualEntry = ""

    // Returns up to 10 nearest restaurants
    var sortedRestaurants: [Restaurant] {
        guard let userLocation = locationManager.location else { return [] }
        return store.restaurants
            .sorted {
                ($0.distance(from: userLocation) ?? Double.greatestFiniteMagnitude) <
                ($1.distance(from: userLocation) ?? Double.greatestFiniteMagnitude)
            }
            .prefix(10)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            VStack {
                if locationManager.authorizationStatus == .authorizedWhenInUse ||
                    locationManager.authorizationStatus == .authorizedAlways {
                    
                    Text("Restaurants Near You").font(.headline).padding(.top)
                    
                    List {
                        ForEach(sortedRestaurants) { restaurant in
                            NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                                VStack(alignment: .leading) {
                                    Text(restaurant.name).font(.headline)
                                    Text(restaurant.address).font(.subheadline).foregroundColor(.secondary)
                                    if let userLoc = locationManager.location,
                                        let dist = restaurant.distance(from: userLoc) {
                                        Text(String(format: "%.0f meters away", dist)).font(.caption)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Text("Please enable location access in Settings to see nearby restaurants.")
                        .padding()
                }
                
                Divider().padding()
                
                VStack {
                    Text("Can't find your restaurant? Enter the name:")
                        .font(.subheadline)
                    TextField("Restaurant name", text: $manualEntry)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    Button("Add or Search") {
                        // Handle manual entry (e.g., show add screen or search)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
                .padding(.bottom)
            }
            .navigationTitle("I'm Here")
        }
    }
}