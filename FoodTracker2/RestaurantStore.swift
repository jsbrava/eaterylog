//
//  RestaurantStore.swift
//  FoodTracker2
//
//  Created by jim on 25/05/2025.
//


import Foundation
import CoreLocation

class RestaurantStore: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    
    init() {
        restaurants = [
            Restaurant(
                name: "Sushi Ota",
                address: "4529 Mission Bay Dr, San Diego, CA 92109",
                latitude: 32.814091,
                longitude: -117.215079,
                placeID: "",
                visits: [
                    Visit(
                        date: Date(),
                        dishes: [
                            Dish(name: "Salmon Nigiri", orderedBy: "Jim", notes: "Excellent, very fresh!", rating: 5),
                            Dish(name: "Eel Roll", orderedBy: "Jane", notes: "Good, but a bit sweet.", rating: 4)
                        ]
                    )
                ]
            ),
            Restaurant(
                name: "Poseidon",
                address: "1670 Coast Blvd, Del Mar, CA 92014",
                latitude: 32.959386,
                longitude: -117.266305,
                placeID: "",
                visits: []
            )
        ]
    }
    func addRestaurantIfNeeded(from suggestion: PlaceSuggestion, completion: @escaping (Restaurant?) -> Void) {
        // Check for existing restaurant
        if let existing = restaurants.first(where: { $0.placeID == suggestion.placeID }) {
            completion(existing)
            return
        }

        // Fetch details
        fetchPlaceDetails(placeID: suggestion.placeID) { address, lat, lng in
            let newRestaurant = Restaurant(
                name: suggestion.description,
                address: address,
                latitude: lat,
                longitude: lng,
                placeID: suggestion.placeID,
                visits: []
            )
            DispatchQueue.main.async {
                self.restaurants.append(newRestaurant)
                completion(newRestaurant)
            }
        }
    }
    
}
extension RestaurantStore {
    func fetchPlaceDetails(placeID: String, completion: @escaping (_ address: String, _ lat: Double, _ lng: Double) -> Void) {
        // Use your API key here, ideally from a config file
        let apiKey = AppConfig.googlePlacesAPIKey
        let urlString = "https://maps.googleapis.com/maps/api/place/details/json?placeid=\(placeID)&fields=name,formatted_address,geometry&key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            completion("", 0.0, 0.0)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion("", 0.0, 0.0)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let result = json["result"] as? [String: Any] {
                    let address = result["formatted_address"] as? String ?? ""
                    var latitude = 0.0
                    var longitude = 0.0
                    if let geometry = result["geometry"] as? [String: Any],
                       let location = geometry["location"] as? [String: Any] {
                        latitude = location["lat"] as? Double ?? 0.0
                        longitude = location["lng"] as? Double ?? 0.0
                    }
                    completion(address, latitude, longitude)
                } else {
                    completion("", 0.0, 0.0)
                }
            } catch {
                completion("", 0.0, 0.0)
            }
        }.resume()
    }
}
