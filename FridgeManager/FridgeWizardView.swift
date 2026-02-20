import SwiftUI
import SwiftData

struct FridgeWizardView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var name: String
    @State private var selectedTypeIndex: Int
    @State private var shelfCount: Int // keep a temp value for simple creation UI
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
        _shelfCount = State(initialValue: (fridge?.shelves.count ?? 3))
    }

    @State private var shelves: [Shelf] = []
    @State private var drawers: [Drawer] = []
    @State private var newShelfName: String = ""
    @State private var newDrawerName: String = ""

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

                    Stepper(value: $shelfCount, in: 0...12) {
                        Text("Initial shelves: \(shelfCount)")
                    }
                }

                Section(header: Text("Shelves")) {
                    ForEach(shelves.indices, id: \.self) { idx in
                        HStack {
                            Text(shelves[idx].name)
                            Spacer()
                            Button("Remove") {
                                shelves.remove(at: idx)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }

                    HStack {
                        TextField("New shelf name", text: $newShelfName)
                        Button("Add") {
                            let s = Shelf(name: newShelfName.isEmpty ? "Shelf \(shelves.count + 1)" : newShelfName, position: shelves.count + 1)
                            shelves.append(s)
                            newShelfName = ""
                        }
                        .disabled(newShelfName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section(header: Text("Drawers")) {
                    ForEach(drawers.indices, id: \.self) { idx in
                        HStack {
                            Text(drawers[idx].name)
                            Spacer()
                            Button("Remove") {
                                drawers.remove(at: idx)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }

                    HStack {
                        TextField("New drawer name", text: $newDrawerName)
                        Button("Add") {
                            let d = Drawer(name: newDrawerName.isEmpty ? "Drawer \(drawers.count + 1)" : newDrawerName, position: drawers.count + 1)
                            drawers.append(d)
                            newDrawerName = ""
                        }
                        .disabled(newDrawerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
            .onAppear {
                // Initialize temp lists from fridge if editing
                if let f = fridge {
                    shelves = f.shelves
                    drawers = f.drawers
                } else {
                    // Prepopulate initial shelves when creating
                    if shelves.isEmpty {
                        for i in 1...shelfCount {
                            shelves.append(Shelf(name: "Shelf \(i)", position: i))
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
                fridge.shelves = shelves
                fridge.drawers = drawers
                try modelContext.save()
            } else {
                let newFridge = Fridge(name: trimmed, type: Self.fridgeTypes[selectedTypeIndex], shelves: shelves, drawers: drawers)
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
