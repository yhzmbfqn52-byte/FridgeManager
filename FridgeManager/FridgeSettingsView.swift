import SwiftUI
import SwiftData

struct FridgeSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var fridges: [Fridge]

    var onDone: (() -> Void)?
    @State private var selectedFridge: Fridge?
    @State private var presentingWizard: Bool = false
    @State private var showingDeleteConfirm: Bool = false

    // Note: use `presentingWizard` for both create and edit flows. When editing, set `selectedFridge` then set `presentingWizard = true`.

    private var defaultFridgeId: UUID? {
        guard let s = UserDefaults.standard.string(forKey: "defaultFridgeId") else { return nil }
        return UUID(uuidString: s)
    }

    var body: some View {
        List {
            Section(header: Text("Fridges")) {
                if fridges.isEmpty {
                    Text("No fridges configured.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(fridges) { fridge in
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(fridge.name)
                                        .font(.headline)
                                    if fridge.id == defaultFridgeId {
                                        Text("(Default)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Text(fridge.type)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Edit") {
                                // Only set the selected fridge; the item-based fullScreenCover will present the editor
                                selectedFridge = fridge
                            }
                            .buttonStyle(.bordered)

                            Button("Set Default") {
                                UserDefaults.standard.set(fridge.id.uuidString, forKey: "defaultFridgeId")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentColor)
                        }
                        // Add swipe actions for quick Edit / Delete
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                // delete this fridge
                                modelContext.delete(fridge)
                                do {
                                    try modelContext.save()
                                    if fridge.id == defaultFridgeId {
                                        UserDefaults.standard.removeObject(forKey: "defaultFridgeId")
                                    }
                                } catch {
                                    print("Failed to delete fridge: \(error)")
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                // Only select the fridge to open edit mode
                                selectedFridge = fridge
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.accentColor)
                        }
                    }
                    .onDelete(perform: deleteFridges)
                }
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Text("Delete All Fridges")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
        .navigationTitle("Settings")
        .toolbar {
            // Done / Close
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { onDone?() }
                    .tint(.accentColor)
            }
            // Add new fridge
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // create new fridge
                    selectedFridge = nil
                    presentingWizard = true
                }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Fridge")
            }
        }
        // Present wizard for editing via item-based cover (passes the Fridge instance to the wizard)
        .fullScreenCover(item: $selectedFridge, onDismiss: {
            // ensure selection is cleared after dismiss
            selectedFridge = nil
        }) { fridge in
            NavigationStack {
                FridgeWizardView(fridge: fridge, onComplete: {
                    // dismiss by clearing the selected fridge
                    selectedFridge = nil
                })
                .environment(\.modelContext, modelContext)
            }
            .ignoresSafeArea()
        }

        // Separate full screen cover for creating a new fridge (when presentingWizard is true and no selectedFridge)
        .fullScreenCover(isPresented: Binding(get: { presentingWizard && selectedFridge == nil }, set: { newValue in
            if !newValue { presentingWizard = false }
        })) {
            NavigationStack {
                FridgeWizardView(fridge: nil, onComplete: {
                    presentingWizard = false
                })
                .environment(\.modelContext, modelContext)
            }
            .ignoresSafeArea()
        }
        .confirmationDialog("Are you sure?", isPresented: $showingDeleteConfirm) {
            Button("Delete All", role: .destructive) {
                deleteAllFridges()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all saved fridges from local storage.")
        }
    }

    private func deleteFridges(offsets: IndexSet) {
        for index in offsets {
            let fridge = fridges[index]
            modelContext.delete(fridge)
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete fridges: \(error)")
        }
    }

    private func deleteAllFridges() {
        for f in fridges {
            modelContext.delete(f)
        }
        do {
            try modelContext.save()
            // Reset first-run flag so wizard reappears if desired
            UserDefaults.standard.set(false, forKey: "hasCompletedWizard")
            UserDefaults.standard.removeObject(forKey: "defaultFridgeId")
            onDone?()
        } catch {
            print("Failed to delete all fridges: \(error)")
        }
    }
}

struct FridgeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FridgeSettingsView()
        }
        .modelContainer(for: [Fridge.self, Shelf.self, Drawer.self], inMemory: true)
        .preferredColorScheme(.dark)
    }
}
