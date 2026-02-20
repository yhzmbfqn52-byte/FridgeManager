import SwiftUI
import SwiftData

struct FridgeWizardView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var name: String
    @State private var selectedTypeIndex: Int
    @State private var shelfCount: Int
    @State private var showingError: Bool = false

    static let fridgeTypes = ["Standard", "Mini", "Double Door", "Smart"]

    var fridge: Fridge?

    var onComplete: (() -> Void)?

    init(fridge: Fridge? = nil, onComplete: (() -> Void)? = nil) {
        self.fridge = fridge
        self.onComplete = onComplete
        _name = State(initialValue: fridge?.name ?? "My Fridge")
        let initialType = fridge?.type ?? Self.fridgeTypes.first!
        _selectedTypeIndex = State(initialValue: Self.fridgeTypes.firstIndex(of: initialType) ?? 0)
        _shelfCount = State(initialValue: fridge?.shelfCount ?? 3)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Fridge Details")) {
                    TextField("Name", text: $name)

                    Picker("Type", selection: $selectedTypeIndex) {
                        ForEach(Self.fridgeTypes.indices, id: \.self) { idx in
                            Text(Self.fridgeTypes[idx]).tag(idx)
                        }
                    }

                    Stepper(value: $shelfCount, in: 1...12) {
                        Text("Shelves: \(shelfCount)")
                    }
                }

                Section {
                    Button(action: saveFridge) {
                        Text(fridge == nil ? "Create Fridge" : "Save Changes")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .tint(.accentColor)

                    if fridge != nil {
                        Button(role: .destructive) {
                            deleteFridge()
                        } label: {
                            Text("Delete Fridge")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .navigationTitle(fridge == nil ? "Setup Fridge" : "Edit Fridge")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onComplete?()
                    }
                }
            }
            .alert(isPresented: $showingError) {
                Alert(title: Text("Invalid Input"), message: Text("Please provide a fridge name."), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func saveFridge() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showingError = true
            return
        }

        do {
            if let fridge = fridge {
                fridge.name = trimmed
                fridge.type = Self.fridgeTypes[selectedTypeIndex]
                fridge.shelfCount = shelfCount
                try modelContext.save()
            } else {
                let newFridge = Fridge(name: trimmed, type: Self.fridgeTypes[selectedTypeIndex], shelfCount: shelfCount)
                modelContext.insert(newFridge)
                try modelContext.save()
                // Mark wizard complete on first creation
                UserDefaults.standard.set(true, forKey: "hasCompletedWizard")
            }

            onComplete?()
        } catch {
            print("Failed to save fridge: \(error)")
            showingError = true
        }
    }

    private func deleteFridge() {
        guard let fridge = fridge else { return }
        do {
            modelContext.delete(fridge)
            try modelContext.save()
            onComplete?()
        } catch {
            print("Failed to delete fridge: \(error)")
            showingError = true
        }
    }
}

struct FridgeWizardView_Previews: PreviewProvider {
    static var previews: some View {
        FridgeWizardView(onComplete: {})
    }
}
