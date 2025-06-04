//
//  RestaurantDetailView.swift
//  FoodTracker2
//
//  Created by jim on 26/05/2025.
//


import SwiftUI

struct RestaurantDetailView: View {
    @ObservedObject var restaurantStore: RestaurantStore
    @State var restaurant: Restaurant

    // New dish input
    @State private var dishName = ""
    @State private var orderedBy = ""
    @State private var notes = ""
    @State private var rating = 0

    // List of new dishes for this visit
    @State private var newDishes: [Dish] = []

    var body: some View {
        VStack(alignment: .leading) {
            Text(restaurant.name)
                .font(.title)
                .padding(.bottom)

            Text(restaurant.address)
                .font(.subheadline)
                .padding(.bottom)

            Text("Previous Visits")
                .font(.headline)
            List(restaurant.visits.suffix(5)) { visit in
                VStack(alignment: .leading) {
                    Text("Visit on \(visit.date.formatted(.dateTime.month().day().year()))")
                        .font(.subheadline)
                    ForEach(visit.dishes) { dish in
                        HStack {
                            Text(dish.name)
                                .bold()
                            Text("- \(dish.orderedBy)")
                                .italic()
                            Spacer()
                            Text("⭐️ \(dish.rating)")
                        }
                        Text(dish.notes)
                            .font(.caption)
                    }
                }
            }
            .frame(height: 200)

            Divider()
                .padding(.vertical)

            // Fields for new dish
            Text("Add a Dish to This Visit")
                .font(.headline)
            TextField("Dish Name", text: $dishName)
                .textFieldStyle(.roundedBorder)
            TextField("Ordered By", text: $orderedBy)
                .textFieldStyle(.roundedBorder)
            TextField("Notes", text: $notes)
                .textFieldStyle(.roundedBorder)
            Stepper("Rating: \(rating)", value: $rating, in: 0...5)

            Button("Add Dish") {
                let newDish = Dish(name: dishName, orderedBy: orderedBy, notes: notes, rating: rating)
                newDishes.append(newDish)
                dishName = ""
                orderedBy = ""
                notes = ""
                rating = 0
            }
            .padding(.vertical)

            // Show new dishes before saving visit
            if !newDishes.isEmpty {
                Text("Dishes for This Visit:")
                    .font(.subheadline)
                ForEach(newDishes) { dish in
                    HStack {
                        Text(dish.name)
                        Spacer()
                        Text("⭐️ \(dish.rating)")
                    }
                }
            }

            Button("Save Visit") {
                let newVisit = Visit(date: Date(), dishes: newDishes)
                restaurantStore.addVisit(to: restaurant, visit: newVisit)
                restaurant = restaurantStore.restaurants.first(where: { $0.id == restaurant.id }) ?? restaurant
                newDishes = []
            }
            .disabled(newDishes.isEmpty)
            .padding(.top)

            Spacer()
        }
        .padding()
    }
}
