//
//  GooglePlacesAutocompleteView.swift
//  FoodTracker2
//
//  Created by jim on 5/26/25.
//


import SwiftUI
import CoreLocation

struct NearbyRestaurantsView: View {
    @ObservedObject var viewModel: PlacesAutocompleteViewModel
    @ObservedObject var locationManager = LocationManager()
    @State private var hasFetched = false
    @State private var lastFetchedLocation: CLLocation?
    var onSelect: (PlaceSuggestion) -> Void

    var body: some View {
        VStack {
            Text("Nearby Restaurants")
                .font(.headline)
                .padding(.top)

            if let _ = locationManager.location {
                List(viewModel.suggestions, id: \.placeID) { suggestion in
                    Button(action: {
                        onSelect(suggestion)
                    }) {
                        Text(suggestion.description)
                    }
                }
            } else {
                ProgressView("Getting your location...")
            }
        }
//        .onAppear {
//            if !hasFetched {
//                hasFetched = true
//                if let location = locationManager.location {
//                    viewModel.fetchNearbyRestaurants(location: location)
//                }
//            }
//        }
//        .onReceive(locationManager.$location) { location in
//            // Fetch when location updates (helpful for first launch)
//            if let location = location {
//                viewModel.fetchNearbyRestaurants(location: location)
//            }
//        }
        .onChange(of: locationManager.location) { newLocation in
            guard let newLocation = newLocation else { return }
            // Only fetch if location changed enough, or not fetched yet
            if !hasFetched || lastFetchedLocation == nil || newLocation.distance(from: lastFetchedLocation!) > 3 {
                hasFetched = true
                lastFetchedLocation = newLocation
                viewModel.fetchNearbyRestaurants(location: newLocation)
            }
        }
    }
}
