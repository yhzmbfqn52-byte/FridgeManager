//
//  ContentView.swift
//  FridgeManager
//
//  Created by Filip Herman on 19/02/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [FridgeItem]
    @Query private var fridges: [Fridge]

    @State private var showingSettings: Bool = false
    @State private var showingAbout: Bool = false
    @State private var showingAddItem: Bool = false
    @State private var showingWizard: Bool = false

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.productName.isEmpty ? "Unnamed product" : item.productName)
                                .font(.title2)
                            Text(locationName(for: item))
                                .foregroundStyle(.secondary)
                            Text("Added: \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                                .foregroundStyle(.secondary)
                            Text("Expires: \(item.expirationDate, format: Date.FormatStyle(date: .numeric))")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.productName.isEmpty ? "(No name)" : item.productName)
                                    .font(.headline)
                                Text(locationName(for: item))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("Expires: \(item.expirationDate, format: Date.FormatStyle(date: .numeric))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden) // ensure dark background shows through
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showingAddItem = true
                        } label: {
                            Image(systemName: "plus")
                        }

                        EditButton()
                            .tint(.accentColor)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("Design Fridge") { showingWizard = true }
                        Button("Settings") { showingSettings = true }
                        Button("About FridgeManager") { showingAbout = true }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .imageScale(.large)
                            .accessibilityLabel("Menu")
                    }
                }
            }
        } detail: {
            Text("Select an item")
                .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                FridgeSettingsView(onDone: { showingSettings = false })
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingAbout) {
            NavigationStack {
                AboutView(onDone: { showingAbout = false })
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingAddItem) {
            NavigationStack {
                AddFridgeItemView(isPresented: $showingAddItem)
                    .environment(\.modelContext, modelContext)
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingWizard) {
            FridgeWizardView(onComplete: { showingWizard = false })
        }
    }

    // Resolve a human readable location name for an item using the fridges' shelves/drawers
    private func locationName(for item: FridgeItem) -> String {
        // First try to find a matching shelf
        for fridge in fridges {
            if let sid = item.shelfId {
                if let shelf = fridge.shelves.first(where: { $0.id == sid }) {
                    return "Shelf: \(shelf.name)"
                }
            }
            if let did = item.drawerId {
                if let drawer = fridge.drawers.first(where: { $0.id == did }) {
                    return "Drawer: \(drawer.name)"
                }
            }
        }
        return "Unassigned"
    }

    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            modelContext.delete(item)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete items: \(error)")
        }
    }
}

// New AddFridgeItemView - collects product name and expiration date, saves to model
struct AddFridgeItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool

    @State private var productName: String = ""
    @State private var expirationDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    @Query private var fridges: [Fridge]

    @State private var selectedFridgeIndex: Int = 0
    @State private var locationType: String = "Shelf" // "Shelf" or "Drawer"
    @State private var selectedShelfIndex: Int = 0
    @State private var selectedDrawerIndex: Int = 0

    var body: some View {
        Form {
            Section(header: Text("Product")) {
                TextField("Product name", text: $productName)
            }

            Section(header: Text("Expiration")) {
                DatePicker("Expiration date", selection: $expirationDate, displayedComponents: .date)
            }

            Section(header: Text("Fridge / Location")) {
                if fridges.isEmpty {
                    Text("No fridges configured. Use the wizard to create one.")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Fridge", selection: $selectedFridgeIndex) {
                        ForEach(fridges.indices, id: \.self) { idx in
                            Text(fridges[idx].name).tag(idx)
                        }
                    }

                    Picker("Location Type", selection: $locationType) {
                        Text("Shelf").tag("Shelf")
                        Text("Drawer").tag("Drawer")
                    }
                    .pickerStyle(.segmented)

                    if locationType == "Shelf" {
                        if fridges[selectedFridgeIndex].shelves.isEmpty {
                            Text("No shelves in the selected fridge")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Shelf", selection: $selectedShelfIndex) {
                                ForEach(fridges[selectedFridgeIndex].shelves.indices, id: \.self) { idx in
                                    Text(fridges[selectedFridgeIndex].shelves[idx].name).tag(idx)
                                }
                            }
                        }
                    } else {
                        if fridges[selectedFridgeIndex].drawers.isEmpty {
                            Text("No drawers in the selected fridge")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Drawer", selection: $selectedDrawerIndex) {
                                ForEach(fridges[selectedFridgeIndex].drawers.indices, id: \.self) { idx in
                                    Text(fridges[selectedFridgeIndex].drawers[idx].name).tag(idx)
                                }
                            }
                        }
                    }
                }
            }

            Section {
                Button("Save") {
                    var shelfId: UUID? = nil
                    var drawerId: UUID? = nil

                    if !fridges.isEmpty {
                        let fridge = fridges[selectedFridgeIndex]
                        if locationType == "Shelf", fridge.shelves.indices.contains(selectedShelfIndex) {
                            shelfId = fridge.shelves[selectedShelfIndex].id
                        }
                        if locationType == "Drawer", fridge.drawers.indices.contains(selectedDrawerIndex) {
                            drawerId = fridge.drawers[selectedDrawerIndex].id
                        }
                    }

                    let newItem = FridgeItem(timestamp: Date(), productName: productName, expirationDate: expirationDate, shelfId: shelfId, drawerId: drawerId)
                    modelContext.insert(newItem)
                    do {
                        try modelContext.save()
                        isPresented = false
                    } catch {
                        print("Failed to save item: \(error)")
                    }
                }
                .disabled(productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || fridges.isEmpty)

                Button("Cancel", role: .cancel) {
                    isPresented = false
                }
            }
        }
        .navigationTitle("Add Item")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    isPresented = false
                }
            }
        }
        .onAppear {
            // default selections: respect saved default fridge ID
            if !fridges.isEmpty {
                if let defaultIdString = UserDefaults.standard.string(forKey: "defaultFridgeId"), let defaultId = UUID(uuidString: defaultIdString), let idx = fridges.firstIndex(where: { $0.id == defaultId }) {
                    selectedFridgeIndex = idx
                } else {
                    selectedFridgeIndex = 0
                }
            }
            locationType = "Shelf"
            selectedShelfIndex = 0
            selectedDrawerIndex = 0
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FridgeItem.self, Fridge.self, Shelf.self, Drawer.self], inMemory: true)
        .preferredColorScheme(.dark)
}
