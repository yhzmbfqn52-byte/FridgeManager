import SwiftUI
import SwiftData
import PhotosUI

extension Notification.Name {
    static let fridgeItemDidUpdate = Notification.Name("fridgeItemDidUpdate")
}

struct EditFridgeItemView: View {
    @Environment(\.modelContext) private var modelContext

    // SwiftData @Model objects are reference types managed by the model context.
    // They should not be annotated with @ObservedObject here. Use a plain model parameter
    // and mutate its properties directly, then save the modelContext.
    var item: FridgeItem
    @Binding var isPresented: Bool

    @State var productName: String = ""
    @State var expirationDate: Date = Date()

    @Query private var fridges: [Fridge]

    @State var selectedFridgeIndex: Int = 0
    @State var locationType: String = "Shelf" // "Shelf" or "Drawer" or "Unassigned"
    @State var selectedShelfIndex: Int = 0
    @State var selectedDrawerIndex: Int = 0

    // image picker state
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var pickedImageData: Data? = nil

    var body: some View {
        NavigationStack {
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
                        // Use a safe fridge reference so we never index out of bounds
                        let safeFridgeIndex = min(max(0, selectedFridgeIndex), max(0, fridges.count - 1))
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
                            if fridges[safeFridgeIndex].shelves.isEmpty {
                                Text("No shelves in the selected fridge")
                                    .foregroundStyle(.secondary)
                            } else {
                                // clamp shelf index
                                let safeShelfIndex = min(max(0, selectedShelfIndex), max(0, fridges[safeFridgeIndex].shelves.count - 1))
                                Picker("Shelf", selection: $selectedShelfIndex) {
                                    ForEach(fridges[safeFridgeIndex].shelves.indices, id: \.self) { idx in
                                        Text(fridges[safeFridgeIndex].shelves[idx].name).tag(idx)
                                    }
                                }
                                .onChange(of: fridges) { _, _ in
                                    // ensure indices remain valid when the fridges array mutates
                                    selectedFridgeIndex = safeFridgeIndex
                                    selectedShelfIndex = safeShelfIndex
                                }
                            }
                        } else if locationType == "Drawer" {
                            if fridges[safeFridgeIndex].drawers.isEmpty {
                                Text("No drawers in the selected fridge")
                                    .foregroundStyle(.secondary)
                            } else {
                                let safeDrawerIndex = min(max(0, selectedDrawerIndex), max(0, fridges[safeFridgeIndex].drawers.count - 1))
                                Picker("Drawer", selection: $selectedDrawerIndex) {
                                    ForEach(fridges[safeFridgeIndex].drawers.indices, id: \.self) { idx in
                                        Text(fridges[safeFridgeIndex].drawers[idx].name).tag(idx)
                                    }
                                }
                                .onChange(of: fridges) { _, _ in
                                    selectedFridgeIndex = safeFridgeIndex
                                    selectedDrawerIndex = safeDrawerIndex
                                }
                            }
                        } else {
                            Text("This item will be unassigned")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Image section
                Section(header: Text("Photo")) {
                    HStack(spacing: 12) {
                        if let data = pickedImageData ?? item.imageData, let ui = UIImage(data: data) {
                            Image(uiImage: ui).resizable().scaledToFill().frame(width: 64, height: 64).clipped().cornerRadius(6)
                        } else {
                            Rectangle().fill(Color.secondary.opacity(0.1)).frame(width: 64, height: 64).cornerRadius(6).overlay(Image(systemName: "photo").foregroundColor(.secondary))
                        }

                        VStack(alignment: .leading) {
                            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                                Text("Choose Photo")
                            }
                            .onChange(of: selectedItem) { newItem in
                                guard let newItem = newItem else { return }
                                Task {
                                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                                        await MainActor.run { pickedImageData = data }
                                    }
                                }
                            }

                            if item.imageData != nil || pickedImageData != nil {
                                Button("Clear Photo", role: .destructive) {
                                    pickedImageData = nil
                                    item.imageData = nil
                                }
                            }
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { isPresented = false }) {
                        Text("Close")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveChanges()
                    }
                }
            }
            .onAppear(perform: populateInitialValues)
            // when fridges update ensure indices stay valid
            .onChange(of: fridges) { _, _ in
                if fridges.isEmpty {
                    selectedFridgeIndex = 0
                    selectedShelfIndex = 0
                    selectedDrawerIndex = 0
                } else {
                    selectedFridgeIndex = min(selectedFridgeIndex, fridges.count - 1)
                    if !fridges[selectedFridgeIndex].shelves.isEmpty {
                        selectedShelfIndex = min(selectedShelfIndex, fridges[selectedFridgeIndex].shelves.count - 1)
                    } else {
                        selectedShelfIndex = 0
                    }

                    if !fridges[selectedFridgeIndex].drawers.isEmpty {
                        selectedDrawerIndex = min(selectedDrawerIndex, fridges[selectedFridgeIndex].drawers.count - 1)
                    } else {
                        selectedDrawerIndex = 0
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        // Ignore only the keyboard safe area so the view adjusts properly when the keyboard appears.
        .ignoresSafeArea(.keyboard)
    }

    // Make this internal so tests can use the initializer instead of relying on onAppear.
    func populateInitialValues() {
        productName = item.productName
        expirationDate = item.expirationDate

        // load existing image into pickedImageData for preview
        pickedImageData = item.imageData

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

    // Exposed helper that performs the save using an explicit ModelContext.
    // Tests can call this directly to verify persistence without relying on the View environment.
    @discardableResult
    func performSave(using context: ModelContext) -> Bool {
        let trimmed = productName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        item.productName = trimmed
        item.expirationDate = expirationDate

        // persist image data if the user picked one
        if let data = pickedImageData {
            item.imageData = data
        }

        // update relationships (best-effort; if fridges is empty this will just clear relations)
        if !fridges.isEmpty {
            let fridgeIndex = min(max(0, selectedFridgeIndex), fridges.count - 1)
            let fridge = fridges[fridgeIndex]
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
            try context.save()
            return true
        } catch {
            print("Failed to save edited item: \(error)")
            return false
        }
    }

    // Restore saveChanges wrapper used by the UI to call the performSave helper and dismiss the sheet.
    func saveChanges() {
        let success = performSave(using: modelContext)
        guard success else { return }

        // Post notification so the master list can clear selection and show the list
        NotificationCenter.default.post(name: .fridgeItemDidUpdate, object: item.id)

        // Dismiss on the main thread to ensure the presenting binding updates cleanly
        DispatchQueue.main.async {
            isPresented = false
        }
    }

    // Testable static helper that applies changes to an item and saves using provided context.
    // This keeps the UI @State private while exposing the save logic for unit tests.
    static func applyChanges(
        to item: FridgeItem,
        productName: String,
        expirationDate: Date,
        locationType: String,
        fridgeIndex: Int,
        shelfIndex: Int,
        drawerIndex: Int,
        fridges: [Fridge],
        context: ModelContext
    ) {
        let trimmed = productName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        item.productName = trimmed
        item.expirationDate = expirationDate

        if !fridges.isEmpty {
            let fi = min(max(0, fridgeIndex), fridges.count - 1)
            let fridge = fridges[fi]
            if locationType == "Shelf", fridge.shelves.indices.contains(shelfIndex) {
                item.shelf = fridge.shelves[shelfIndex]
                item.drawer = nil
            } else if locationType == "Drawer", fridge.drawers.indices.contains(drawerIndex) {
                item.drawer = fridge.drawers[drawerIndex]
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
            try context.save()
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
