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
    @ObservedObject var restaurantStore: RestaurantStore
    @ObservedObject var locationManager = LocationManager()
    @State private var hasFetched = false
    @State private var lastFetchedLocation: CLLocation?
    
    @State private var searchQuery: String = ""
    @State private var searchResults: [PlaceSuggestion] = []
    @State private var isSearching: Bool = false

    var onSelect: (PlaceSuggestion) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Nearby Restaurants")
                .font(.title2)
                .fontWeight(.semibold)

            if let userLocation = locationManager.location {
                List(viewModel.suggestions, id: \.placeID) { suggestion in
                    let isVisited = restaurantStore.restaurants.contains {
                        $0.placeID == suggestion.placeID && !$0.visits.isEmpty
                    }
                    let distanceString: String = {
                        if let lat = suggestion.latitude, let lng = suggestion.longitude {
                            let restaurantLoc = CLLocation(latitude: lat, longitude: lng)
                            let meters = userLocation.distance(from: restaurantLoc)
                            let miles = meters / 1609.34
                            return String(format: " – %.1f mi", miles)
                        } else {
                            return ""
                        }
                    }()

                    Button(action: {
                        onSelect(suggestion)
                    }) {
                        Text(suggestion.description + distanceString)
                            .fontWeight(isVisited ? .bold : .regular)
                            .foregroundColor(.blue)
                    }
                }
                .listStyle(PlainListStyle())
                .frame(maxHeight: 250)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 16)
            } else {
                ProgressView("Getting your location...")
            }

            Divider()
                .padding(.vertical, 8)
            
            Text("Can't find it? Search:")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack {
                TextField("Enter restaurant name...", text: $searchQuery, onCommit: {
                    searchRestaurants()
                })
                .font(.title2)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .multilineTextAlignment(.center)
                
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.7)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 2)
            
            if !searchResults.isEmpty, let userLocation = locationManager.location {
                List(searchResults, id: \.placeID) { suggestion in
                    let isVisited = restaurantStore.restaurants.contains {
                        $0.placeID == suggestion.placeID && !$0.visits.isEmpty
                    }
                    let distanceString: String = {
                        if let lat = suggestion.latitude, let lng = suggestion.longitude {
                            let restaurantLoc = CLLocation(latitude: lat, longitude: lng)
                            let meters = userLocation.distance(from: restaurantLoc)
                            let miles = meters / 1609.34
                            return String(format: " – %.1f mi", miles)
                        } else {
                            return ""
                        }
                    }()

                    Button(action: {
                        onSelect(suggestion)
                    }) {
                        Text(suggestion.description + distanceString)
                            .fontWeight(isVisited ? .bold : .regular)
                            .foregroundColor(.blue)
                    }
                }
                .listStyle(PlainListStyle())
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 16)
                // Remove .frame(maxHeight:) so it uses the remaining space, or adjust as needed
            }
            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 8)
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

        if let userLocation = locationManager.location {
            viewModel.searchRestaurants(query: searchQuery, userLocation: userLocation) { results in
                DispatchQueue.main.async {
                    self.searchResults = results
                    self.isSearching = false
                }
            }
        } else {
            self.isSearching = false
        }
    }
}
