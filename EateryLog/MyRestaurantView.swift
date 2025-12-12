//
//  RestaurantSortOption.swift
//  EateryLog
//
//  Created by jim on 7/5/25.
//

import SwiftUI
import CoreLocation
import ZIPFoundation

enum RestaurantSortOption: String, CaseIterable, Identifiable {
    case distance = "Distance"
    case alphabetical = "A–Z"
    var id: String { self.rawValue }
}

struct MyRestaurantsView: View {
    @ObservedObject var restaurantStore: RestaurantStore
    @ObservedObject var locationManager = LocationManager.shared
    var onSelect: (Restaurant) -> Void
    @State private var sortOption: RestaurantSortOption = .distance
    @State private var isSharingExport = false
    @State private var exportURL: URL?

    var sortedRestaurants: [Restaurant] {
        let restaurants = restaurantStore.restaurants

        switch sortOption {
        case .distance:
            guard let userLocation = locationManager.location else {
                return restaurants
            }
            return restaurants.sorted { lhs, rhs in
                let lhsDistance = lhs.distance(from: userLocation) ?? .greatestFiniteMagnitude
                let rhsDistance = rhs.distance(from: userLocation) ?? .greatestFiniteMagnitude
                return lhsDistance < rhsDistance
            }
        case .alphabetical:
            return restaurants.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
    }

    var body: some View {
        VStack {
            Picker("Sort by", selection: $sortOption) {
                ForEach(RestaurantSortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List {
                ForEach(sortedRestaurants) { restaurant in
                    RestaurantRowView(restaurant: restaurant, sortOption: sortOption, userLocation: locationManager.location) {
                        onSelect(restaurant)
                    }
                }
                .onDelete(perform: deleteRestaurant)
            }
            .listStyle(.inset)

            Button("Export as ZIP") {
                exportData()
            }
            .padding()
        }
        .navigationTitle("My Restaurants")
        .sheet(isPresented: $isSharingExport) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    private func deleteRestaurant(at offsets: IndexSet) {
        let fileManager = FileManager.default
        let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        for index in offsets {
            let restaurant = sortedRestaurants[index]
            for filename in restaurant.imageFileNames {
                let imageURL = docURL.appendingPathComponent(filename)
                try? fileManager.removeItem(at: imageURL)
            }
            if let actualIndex = restaurantStore.restaurants.firstIndex(where: { $0.id == restaurant.id }) {
                restaurantStore.restaurants.remove(at: actualIndex)
            }
        }

        restaurantStore.save()
    }

    private func exportData() {
        let fileManager = FileManager.default
        let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportURL = docURL.appendingPathComponent("EateryExport.zip")
        print("Start export: \(docURL.path) → \(exportURL.path)")

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                print("Entered background queue for zipping")
                if fileManager.fileExists(atPath: exportURL.path) {
                    print("Deleting existing zip file")
                    try fileManager.removeItem(at: exportURL)
                }
                print("Creating new ZIP archive...")
                guard let archive = Archive(url: exportURL, accessMode: .create) else {
                    print("Failed to create ZIP archive")
                    return
                }

                let jsonURL = docURL.appendingPathComponent("restaurants.json")
                if fileManager.fileExists(atPath: jsonURL.path) {
                    try archive.addEntry(with: "restaurants.json", fileURL: jsonURL)
                    print("Added restaurants.json")
                }

                // Add images referenced by the database
                for restaurant in restaurantStore.restaurants {
                    for filename in restaurant.imageFileNames {
                        let imgURL = docURL.appendingPathComponent(filename)
                        if fileManager.fileExists(atPath: imgURL.path) {
                            try archive.addEntry(with: filename, fileURL: imgURL)
                            print("Added image \(filename)")
                        }
                    }
                }

                print("All files added, switching to main thread...")
                DispatchQueue.main.async {
                    self.exportURL = exportURL
                    self.isSharingExport = true
                    print("✅ Export complete. Ready to share: \(exportURL)")
                }
            } catch {
                print("❌ ZIP export failed: \(error)")
                DispatchQueue.main.async {
                    // Optionally: show an alert
                }
            }
        }
    }
}

struct RestaurantRowView: View {
    let restaurant: Restaurant
    let sortOption: RestaurantSortOption
    let userLocation: CLLocation?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(restaurant.name)
                    .fontWeight(restaurant.visits.isEmpty ? .regular : .bold)
                    .foregroundColor(.blue)
                Spacer()
                if sortOption == .distance, let userLocation {
                    Text(restaurant.formattedDistance(from: userLocation))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
