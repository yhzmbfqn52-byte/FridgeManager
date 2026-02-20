import SwiftUI
import SwiftData

struct FridgeSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var fridges: [Fridge]

    var onDone: (() -> Void)?
    @State private var showingWizardForEdit: Bool = false
    @State private var selectedFridge: Fridge?
    @State private var showingDeleteConfirm: Bool = false

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
                                selectedFridge = fridge
                                showingWizardForEdit = true
                            }
                            .buttonStyle(.bordered)

                            Button("Set Default") {
                                UserDefaults.standard.set(fridge.id.uuidString, forKey: "defaultFridgeId")
                            }
                            .buttonStyle(.borderedProminent)
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
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { onDone?() }
                    .tint(.accentColor)
            }
        }
        .sheet(isPresented: $showingWizardForEdit) {
            if let fridge = selectedFridge {
                FridgeWizardView(fridge: fridge, onComplete: { showingWizardForEdit = false })
            }
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
