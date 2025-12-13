//
//  PlacesAutocompleteViewModel.swift
//  FoodTracker2
//
//  Created by jim on 5/26/25.
//


import Foundation
import Combine
import CoreLocation

class PlacesAutocompleteViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var suggestions: [PlaceSuggestion] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let apiKey = AppConfig.googlePlacesAPIKey
    
    func fetchSuggestions(query: String, location: CLLocation?) {
        // If no location, skip search (or you can fallback to a default location if you want)
        guard let location = location else {
            print("No location available, skipping fetch.")
            return
        }
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&key=\(apiKey)&types=restaurant&location=\(lat),\(lng)&radius=16"
        print("URL: \(urlString)")
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            print("Network callback: data=\(data != nil), error=\(error?.localizedDescription ?? "none")")
            
            if let error = error {
                print("Network error: \(error.localizedDescription)")
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP status code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            // Print the raw server response (may be HTML, JSON, or error)
            //print("Raw response: \(String(data: data, encoding: .utf8) ?? "Non-UTF8 data")")
            
            // Now try to parse JSON if possible
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("Could not decode JSON")
                return
            }
            //print("Parsed JSON: \(json)")
            
            guard let predictions = json["predictions"] as? [[String: Any]] else {
                print("No predictions found")
                DispatchQueue.main.async {
                    self.suggestions = []
                }
                return
            }

            let results: [PlaceSuggestion] = predictions.compactMap { pred in
                guard let description = pred["description"] as? String,
                      let placeID = pred["place_id"] as? String else { return nil }
                return PlaceSuggestion(description: description, placeID: placeID)
            }
            DispatchQueue.main.async {
                self.suggestions = results
            }
        }.resume()
    }
    func fetchNearbyRestaurants(location: CLLocation?) {
        guard let location = location else {
            print("No location available, skipping fetch.")
            return
        }

        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude

        let urlString =
            "https://maps.googleapis.com/maps/api/place/nearbysearch/json" +
            "?location=\(lat),\(lng)" +
            "&rankby=distance" +
            "&type=restaurant" +
            "&key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            print("Nearby: invalid URL")
            return
        }

        // print("Nearby URL:", urlString)

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let http = response as? HTTPURLResponse {
                print("Nearby HTTP status:", http.statusCode)
            }

            if let error = error {
                print("Nearby network error:", error.localizedDescription)
                return
            }

            guard let data = data else {
                print("Nearby: no data returned")
                return
            }

            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("Nearby: response was not a JSON dictionary")
                    return
                }

                if let status = json["status"] as? String {
                    print("Nearby Google status:", status,
                          "error_message:", json["error_message"] as? String ?? "none")
                }

                guard let results = json["results"] as? [[String: Any]] else {
                    print("Nearby: missing 'results' in response")
                    return
                }

                let suggestions: [PlaceSuggestion] = results.prefix(8).compactMap { place in
                    guard
                        let name = place["name"] as? String,
                        let placeID = place["place_id"] as? String,
                        let geometry = place["geometry"] as? [String: Any],
                        let locationDict = geometry["location"] as? [String: Any],
                        let lat = locationDict["lat"] as? Double,
                        let lng = locationDict["lng"] as? Double
                    else { return nil }

                    var suggestion = PlaceSuggestion(description: name, placeID: placeID)
                    suggestion.latitude = lat
                    suggestion.longitude = lng
                    return suggestion
                }

                let sortedSuggestions = suggestions.sorted { a, b in
                    guard
                        let alat = a.latitude, let alng = a.longitude,
                        let blat = b.latitude, let blng = b.longitude
                    else { return false }

                    let aloc = CLLocation(latitude: alat, longitude: alng)
                    let bloc = CLLocation(latitude: blat, longitude: blng)
                    return location.distance(from: aloc) < location.distance(from: bloc)
                }

                DispatchQueue.main.async {
                    self.suggestions = sortedSuggestions
                }
            } catch {
                print("Nearby JSON error:", error.localizedDescription)
            }
        }
        .resume()
    }
    func fetchPlaceDetails(placeID: String, completion: @escaping (String, Double, Double) -> Void) {
        let apiKey = AppConfig.googlePlacesAPIKey
        let urlString = "https://maps.googleapis.com/maps/api/place/details/json?placeid=\(placeID)&fields=name,formatted_address,geometry&key=\(apiKey)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
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

                    DispatchQueue.main.async {
                        completion(address, latitude, longitude)
                    }
                }
            } catch {
                print("Error parsing place details: \(error.localizedDescription)")
            }
        }.resume()
    }
    func searchRestaurants(
        query: String,
        userLocation: CLLocation,
        completion: @escaping ([PlaceSuggestion]) -> Void
    ) {
        let queryEncoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(queryEncoded)&types=establishment&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Search error: \(error)")
                completion([])
                return
            }
            guard let data = data else {
                completion([])
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let predictions = json["predictions"] as? [[String: Any]] {
                    let suggestions = predictions.prefix(5).compactMap { place -> PlaceSuggestion? in
                        guard let description = place["description"] as? String,
                              let placeID = place["place_id"] as? String else { return nil }
                        return PlaceSuggestion(description: description, placeID: placeID)
                    }
                    self.filterAndSortRestaurantSuggestions(
                        suggestions: suggestions,
                        userLocation: userLocation
                    ) { sortedRestaurants in
                        completion(sortedRestaurants)
                    }
                } else {
                    completion([])
                }
            } catch {
                print("JSON parse error: \(error)")
                completion([])
            }
        }.resume()
    }
    func filterAndSortRestaurantSuggestions(
        suggestions: [PlaceSuggestion],
        userLocation: CLLocation,
        completion: @escaping ([PlaceSuggestion]) -> Void
    ) {
        let group = DispatchGroup()
        var filtered: [PlaceSuggestion] = []

        for suggestion in suggestions {
            group.enter()
            fetchPlaceDetailsForTypeAndLocation(placeID: suggestion.placeID) { types, lat, lng in
                if types.contains("restaurant"), let lat = lat, let lng = lng {
                    var s = suggestion
                    s.latitude = lat
                    s.longitude = lng
                    filtered.append(s)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let sorted = filtered.sorted {
                guard let lat1 = $0.latitude, let lng1 = $0.longitude,
                      let lat2 = $1.latitude, let lng2 = $1.longitude else { return false }
                let loc1 = CLLocation(latitude: lat1, longitude: lng1)
                let loc2 = CLLocation(latitude: lat2, longitude: lng2)
                return userLocation.distance(from: loc1) < userLocation.distance(from: loc2)
            }
            completion(sorted)
        }
    }

    private func fetchPlaceDetailsForType(placeID: String, completion: @escaping ([String]) -> Void) {
        let apiKey = AppConfig.googlePlacesAPIKey
        let urlString = "https://maps.googleapis.com/maps/api/place/details/json?placeid=\(placeID)&fields=types&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let result = json["result"] as? [String: Any],
                  let types = result["types"] as? [String] else {
                completion([])
                return
            }
            completion(types)
        }.resume()
    }
    
    func enrichSuggestionsWithCoordinates(
        _ suggestions: [PlaceSuggestion],
        completion: @escaping ([PlaceSuggestion]) -> Void
    ) {
        var enriched: [PlaceSuggestion] = []
        let group = DispatchGroup()

        for suggestion in suggestions {
            group.enter()
            fetchPlaceDetails(placeID: suggestion.placeID) { _, lat, lng in
                var copy = suggestion
                copy.latitude = lat
                copy.longitude = lng
                enriched.append(copy)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(enriched)
        }
    }
    
    private func fetchPlaceDetailsForTypeAndLocation(
        placeID: String,
        completion: @escaping (_ types: [String], _ lat: Double?, _ lng: Double?) -> Void
    ) {
        let apiKey = AppConfig.googlePlacesAPIKey
        let urlString = "https://maps.googleapis.com/maps/api/place/details/json?placeid=\(placeID)&fields=types,geometry&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion([], nil, nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let result = json["result"] as? [String: Any],
                  let types = result["types"] as? [String] else {
                completion([], nil, nil)
                return
            }
            var lat: Double? = nil
            var lng: Double? = nil
            if let geometry = result["geometry"] as? [String: Any],
               let location = geometry["location"] as? [String: Any] {
                lat = location["lat"] as? Double
                lng = location["lng"] as? Double
            }
            completion(types, lat, lng)
        }.resume()
    }
}
