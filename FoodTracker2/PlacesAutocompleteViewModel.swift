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
            "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(lat),\(lng)&rankby=distance&type=restaurant&key=\(apiKey)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {
                    let suggestions: [PlaceSuggestion] = results.prefix(8).compactMap { place in
                        guard let name = place["name"] as? String,
                              let placeID = place["place_id"] as? String else { return nil }
                        return PlaceSuggestion(description: name, placeID: placeID)
                    }
                    DispatchQueue.main.async {
                        self.suggestions = suggestions
                    }
                }
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }
        }.resume()
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
}
