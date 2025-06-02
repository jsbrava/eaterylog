//
//  RestaurantDetailView.swift
//  FoodTracker2
//
//  Created by jim on 26/05/2025.
//


import SwiftUI

struct RestaurantDetailView: View {
    let restaurant: Restaurant

    // Helper to get the last 5 visits, most recent first
    var recentVisits: [Visit] {
        restaurant.visits
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Restaurant Name
            Text(restaurant.name)
                .font(.largeTitle)
                .fontWeight(.bold)

            // Address
            Text(restaurant.address)
                .font(.headline)
                .foregroundColor(.secondary)

            Divider()

            // Visits Section
            Text("Recent Visits")
                .font(.title2)
                .fontWeight(.semibold)

            if recentVisits.isEmpty {
                Text("No visits recorded yet")
                    .italic()
                    .foregroundColor(.secondary)
            } else {
                ForEach(recentVisits) { visit in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Visited: \(dateString(visit.date))")
                            .font(.subheadline)
                            .foregroundColor(.blue)

                        if visit.dishes.isEmpty {
                            Text("No dishes recorded for this visit")
                                .italic()
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(visit.dishes) { dish in
                                HStack {
                                    Text(dish.name)
                                    Spacer()
                                    Text("⭐️ \(dish.rating)")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    Divider()
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Restaurant Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Helper for formatting dates
    func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
