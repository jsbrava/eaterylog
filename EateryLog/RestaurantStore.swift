//
//  RestaurantStore.swift
//  FoodTracker2
//
//  Created by jim on 25/05/2025.
//


import Foundation
import CoreLocation
import Combine

class RestaurantStore: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    private var cancellables = Set<AnyCancellable>()
    private let savePath = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("restaurants.json")
    
    init() {
        load()
        if restaurants.isEmpty {
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
        // Combine: autosave when restaurants changes
        $restaurants
            .sink { [weak self] _ in self?.save() }
            .store(in: &cancellables)
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
    func addVisit(to restaurant: Restaurant, visit: Visit) {
        // Find the index of the restaurant in the array
        if let index = restaurants.firstIndex(where: { $0.id == restaurant.id }) {
            restaurants[index].visits.append(visit)
            save() // <-- if you have a save() method for persistence
        }
    }
    // Load restaurants from disk
    func load() {
        do {
            let data = try Data(contentsOf: savePath)
            let decoded = try JSONDecoder().decode([Restaurant].self, from: data)
            self.restaurants = decoded
        } catch {
            print("Failed to load restaurants: \(error)")
        }
    }
    // Save restaurants to disk
    func save() {
        do {
            let data = try JSONEncoder().encode(restaurants)
            try data.write(to: savePath)
        } catch {
            print("Failed to save restaurants: \(error)")
        }
    }
    func deleteVisit(from restaurant: Restaurant, at visitIndex: Int) {
        // Find the index of the restaurant in the array
        if let restIndex = restaurants.firstIndex(where: { $0.id == restaurant.id }) {
            guard visitIndex < restaurants[restIndex].visits.count else { return }
            restaurants[restIndex].visits.remove(at: visitIndex)
            save() // Persist the change
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
