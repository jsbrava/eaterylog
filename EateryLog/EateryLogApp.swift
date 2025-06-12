//
//  FoodTracker2App.swift
//  FoodTracker2
//
//  Created by jim on 25/05/2025.
//

import SwiftUI

@main
struct EateryLogApp: App {
    @StateObject private var store = RestaurantStore()
    var body: some Scene {
        WindowGroup {
            //ImHereView() // <- Change to your "I'm Here" view
            ContentView()
                .environmentObject(store)
        }
    }
}
