//
//  EditDishView.swift
//  EateryLog
//
//  Created by jim on 7/3/25.
//
import SwiftUI

struct EditDishView: View {
    @State var dish: Dish
    var onSave: (Dish) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationView {
            Form {
                TextField("Dish Name", text: $dish.name)
                TextField("Ordered By", text: $dish.orderedBy)
                TextField("Notes", text: $dish.notes)
                Stepper("Rating: \(dish.rating)", value: $dish.rating, in: 0...5)
            }
            .navigationBarTitle("Edit Dish", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(dish)
                    }
                }
            }
        }
    }
}
