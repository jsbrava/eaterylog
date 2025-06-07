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
    
    @State private var searchQuery: String = ""
    @State private var searchResults: [PlaceSuggestion] = []
    @State private var isSearching: Bool = false

    var onSelect: (PlaceSuggestion) -> Void

    var body: some View {
        VStack(alignment: .leading) {
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
                .frame(height: CGFloat(viewModel.suggestions.count * 44 + 10)) // Approximate height for 5 rows
            } else {
                ProgressView("Getting your location...")
            }

            Divider()
                .padding(.vertical, 8)

            Text("Can't find it? Search:")
                .font(.subheadline)
            HStack {
                TextField("Enter restaurant name...", text: $searchQuery, onCommit: {
                    searchRestaurants()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(.bottom, 2)

            if !searchResults.isEmpty {
                List(searchResults, id: \.placeID) { suggestion in
                    Button(action: {
                        onSelect(suggestion)
                    }) {
                        Text(suggestion.description)
                    }
                }
                .frame(height: CGFloat(searchResults.count * 44 + 10)) // adjust if needed
            }
        }
        .onAppear {
            if !hasFetched {
                hasFetched = true
                if let location = locationManager.location {
                    viewModel.fetchNearbyRestaurants(location: location)
                }
            }
        }
        .onReceive(locationManager.$location) { newLocation in
            guard let newLocation = newLocation else { return }
            if lastFetchedLocation == nil || lastFetchedLocation!.distance(from: newLocation) > 100 {
                lastFetchedLocation = newLocation
                viewModel.fetchNearbyRestaurants(location: newLocation)
            }
        }
    }

    private func searchRestaurants() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        viewModel.searchRestaurants(query: searchQuery) { results in
            DispatchQueue.main.async {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }
}
