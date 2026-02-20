import SwiftUI
import SwiftData

struct EditFridgeItemView: View {
    @Environment(\.modelContext) private var modelContext

    var item: FridgeItem
    @Binding var isPresented: Bool

    @State private var productName: String = ""
    @State private var expirationDate: Date = Date()

    @Query private var fridges: [Fridge]

    @State private var selectedFridgeIndex: Int = 0
    @State private var locationType: String = "Shelf" // "Shelf" or "Drawer" or "Unassigned"
    @State private var selectedShelfIndex: Int = 0
    @State private var selectedDrawerIndex: Int = 0

    var body: some View {
        Form {
            Section(header: Text("Product")) {
                TextField("Product name", text: $productName)
            }

            Section(header: Text("Added")) {
                // readonly timestamp
                Text(item.timestamp, style: .date)
                    .foregroundStyle(.secondary)
                Text(item.timestamp, style: .time)
                    .foregroundStyle(.secondary)
            }

            Section(header: Text("Expiration")) {
                DatePicker("Expiration date", selection: $expirationDate, displayedComponents: .date)
            }

            Section(header: Text("Location")) {
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
                        Text("Unassigned").tag("Unassigned")
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
                    } else if locationType == "Drawer" {
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
                    } else {
                        Text("This item will be unassigned")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button("Save") {
                    saveChanges()
                }
                .disabled(productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Cancel", role: .cancel) {
                    isPresented = false
                }
            }
        }
        .navigationTitle("Edit Item")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    saveChanges()
                }
            }
        }
        .onAppear(perform: populateInitialValues)
    }

    private func populateInitialValues() {
        productName = item.productName
        expirationDate = item.expirationDate

        // default fridge selection: find fridge that contains the item's shelf or drawer
        if let shelf = item.shelf {
            if let fridgeIndex = fridges.firstIndex(where: { $0.shelves.contains(where: { $0.id == shelf.id }) }) {
                selectedFridgeIndex = fridgeIndex
                locationType = "Shelf"
                if let sIndex = fridges[fridgeIndex].shelves.firstIndex(where: { $0.id == shelf.id }) {
                    selectedShelfIndex = sIndex
                } else {
                    selectedShelfIndex = 0
                }
                return
            }
        }

        if let drawer = item.drawer {
            if let fridgeIndex = fridges.firstIndex(where: { $0.drawers.contains(where: { $0.id == drawer.id }) }) {
                selectedFridgeIndex = fridgeIndex
                locationType = "Drawer"
                if let dIndex = fridges[fridgeIndex].drawers.firstIndex(where: { $0.id == drawer.id }) {
                    selectedDrawerIndex = dIndex
                } else {
                    selectedDrawerIndex = 0
                }
                return
            }
        }

        // fallback
        selectedFridgeIndex = fridges.isEmpty ? 0 : 0
        locationType = "Shelf"
        selectedShelfIndex = 0
        selectedDrawerIndex = 0
    }

    private func saveChanges() {
        let trimmed = productName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        item.productName = trimmed
        item.expirationDate = expirationDate

        // update relationships
        if !fridges.isEmpty {
            let fridge = fridges[selectedFridgeIndex]
            if locationType == "Shelf", fridge.shelves.indices.contains(selectedShelfIndex) {
                item.shelf = fridge.shelves[selectedShelfIndex]
                item.drawer = nil
            } else if locationType == "Drawer", fridge.drawers.indices.contains(selectedDrawerIndex) {
                item.drawer = fridge.drawers[selectedDrawerIndex]
                item.shelf = nil
            } else {
                item.shelf = nil
                item.drawer = nil
            }
        } else {
            item.shelf = nil
            item.drawer = nil
        }

        do {
            try modelContext.save()
            isPresented = false
        } catch {
            print("Failed to save edited item: \(error)")
        }
    }
}

struct EditFridgeItemView_Previews: PreviewProvider {
    static var previewItem = FridgeItem(timestamp: Date(), productName: "Yogurt", expirationDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!)

    static var previews: some View {
        EditFridgeItemView(item: previewItem, isPresented: .constant(true))
            .modelContainer(for: [FridgeItem.self, Fridge.self, Shelf.self, Drawer.self], inMemory: true)
    }
}
