//
//  RestaurantDetailView.swift
//  FoodTracker2
//
//  Created by jim on 26/05/2025.
//


import SwiftUI

struct RestaurantDetailView: View {
    @ObservedObject var restaurantStore: RestaurantStore
    let restaurantID: String   // The id (placeID)
    
    // Always get the latest from the store
    var restaurant: Restaurant? {
        restaurantStore.restaurants.first(where: { $0.id == restaurantID })
    }
    
    @State private var dishName = ""
    @State private var orderedBy = ""
    @State private var notes = ""
    @State private var rating = 0
    @State private var newDishes: [Dish] = []
    @State private var dishToEdit: EditableDishContext?
    
    var onAddVisit: ((Visit) -> Void)? = nil
    var onCancel: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading) {
            if let restaurant = restaurant {
                Text(restaurant.name)
                    .font(.title)
                    .padding(.bottom)
                Text(restaurant.address)
                    .font(.subheadline)
                    .padding(.bottom)

                Text("Previous Visits").font(.headline)
                List {
                    ForEach(Array(restaurant.visits.suffix(5).enumerated()), id: \.element.id) { visitIndex, visit in
                        Section(header: Text("Visit on \(visit.date.formatted(.dateTime.month().day().year()))").font(.subheadline)) {
                            ForEach(Array(visit.dishes.enumerated()), id: \.element.id) { dishIndex, dish in
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(dish.name).bold()
                                        Text("- \(dish.orderedBy)").italic()
                                        Spacer()
                                        Text("⭐️ \(dish.rating)")
                                    }
                                    if !dish.notes.isEmpty {
                                        Text(dish.notes)
                                            .font(.caption)
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteDish(visitIndex: realVisitIndex(restaurant, visibleIndex: visitIndex), dishIndex: dishIndex)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        dishToEdit = EditableDishContext(
                                            visitIndex: realVisitIndex(restaurant, visibleIndex: visitIndex),
                                            dish: dish
                                        )
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(height: 200)
                .sheet(item: $dishToEdit) { editableContext in
                    EditDishView(
                        dish: editableContext.dish,
                        onSave: { updatedDish in
                            editDish(visitIndex: editableContext.visitIndex, updatedDish: updatedDish)
                            dishToEdit = nil
                        },
                        onCancel: {
                            dishToEdit = nil
                        }
                    )
                }

                Divider().padding(.vertical)

                Text("Add a Dish to This Visit").font(.headline)
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

                if !newDishes.isEmpty {
                    Text("Dishes for This Visit:").font(.subheadline)
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
                    if let onAddVisit = onAddVisit {
                        onAddVisit(newVisit)
                    } else {
                        restaurantStore.addVisit(to: restaurant, visit: newVisit)
                    }
                    newDishes = []
                }
                .disabled(newDishes.isEmpty)
                .padding(.top)

                Spacer()
            } else {
                Text("Restaurant not found.").foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    // Helper: Convert visible visit index to real index
    private func realVisitIndex(_ restaurant: Restaurant, visibleIndex: Int) -> Int {
        let allVisits = restaurant.visits
        let lastFive = allVisits.suffix(5)
        return allVisits.count - lastFive.count + visibleIndex
    }
    
    // Delete Dish Handler
    private func deleteDish(visitIndex: Int, dishIndex: Int) {
        guard let restaurant = restaurant else { return }
        var updatedRestaurant = restaurant
        guard visitIndex < updatedRestaurant.visits.count else { return }
        var visit = updatedRestaurant.visits[visitIndex]
        visit.dishes.remove(at: dishIndex)
        if visit.dishes.isEmpty {
            updatedRestaurant.visits.remove(at: visitIndex)
        } else {
            updatedRestaurant.visits[visitIndex] = visit
        }
        restaurantStore.updateRestaurant(updatedRestaurant)
    }

    // Edit Dish Handler
    private func editDish(visitIndex: Int, updatedDish: Dish) {
        guard let restaurant = restaurant else { return }
        var updatedRestaurant = restaurant
        guard visitIndex < updatedRestaurant.visits.count else { return }
        var visit = updatedRestaurant.visits[visitIndex]
        if let dishIndex = visit.dishes.firstIndex(where: { $0.id == updatedDish.id }) {
            visit.dishes[dishIndex] = updatedDish
            updatedRestaurant.visits[visitIndex] = visit
            restaurantStore.updateRestaurant(updatedRestaurant)
        }
    }
}

struct EditableDishContext: Identifiable {
    var id: UUID { dish.id }
    let visitIndex: Int
    var dish: Dish
}
