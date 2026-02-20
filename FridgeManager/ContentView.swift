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
    @Query private var items: [Item]

    @State private var showingSettings: Bool = false
    @State private var showingAbout: Bool = false

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden) // ensure dark background shows through
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .tint(.accentColor)
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

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .preferredColorScheme(.dark)
}
