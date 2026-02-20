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

    @State private var showingSettings: Bool = false
    @State private var showingAbout: Bool = false
    @State private var showingAddItem: Bool = false

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.productName.isEmpty ? "Unnamed product" : item.productName)
                                .font(.title2)
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

    var body: some View {
        Form {
            Section(header: Text("Product")) {
                TextField("Product name", text: $productName)
            }

            Section(header: Text("Expiration")) {
                DatePicker("Expiration date", selection: $expirationDate, displayedComponents: .date)
            }

            Section {
                Button("Save") {
                    let newItem = FridgeItem(timestamp: Date(), productName: productName, expirationDate: expirationDate)
                    modelContext.insert(newItem)
                    do {
                        try modelContext.save()
                        isPresented = false
                    } catch {
                        print("Failed to save item: \(error)")
                    }
                }
                .disabled(productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FridgeItem.self, inMemory: true)
        .preferredColorScheme(.dark)
}
