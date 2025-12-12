//
//  AppConfig.swift
//  FoodTracker2
//
//  Created by jim on 5/29/25.
//

import Foundation

struct AppConfig {
    static var googlePlacesAPIKey: String {
        guard
            let key = Bundle.main.object(
                forInfoDictionaryKey: "GOOGLE_PLACES_API_KEY"
            ) as? String,
            !key.isEmpty
        else {
            assertionFailure("Missing GOOGLE_PLACES_API_KEY")
            return ""
        }
        return key
    }
}

