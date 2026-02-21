//
//  ContentView.swift
//  FridgeManager
//
//  Created by Filip Herman on 19/02/2026.
//

import SwiftUI
import SwiftData
import PhotosUI
import MessageUI
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [FridgeItem]
    @Query private var fridges: [Fridge]

    @State private var selectedItemID: UUID? = nil
    @State private var editingItem: FridgeItem? = nil

    @State private var showingAddItem: Bool = false
    @State private var showingWizard: Bool = false
    @State private var showingSettings: Bool = false
    @State private var showingAbout: Bool = false

    @State private var itemsLoaded: Bool = false
    @State private var showExpiringOnly: Bool = false
    // Email UI state
    @State private var showingEmailPrompt: Bool = false
    @State private var emailAddress: String = ""
    @State private var showingMailComposer: Bool = false
    @State private var mailBody: String = ""
    @State private var mailRecipients: [String] = []
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var showingShareSheet: Bool = false

    var body: some View {
        NavigationSplitView {
             sidebar
         } detail: {
             detail
         }
        .onReceive(NotificationCenter.default.publisher(for: .fridgeItemDidUpdate)) { _ in
            selectedItemID = nil
        }
        .task(id: editingItem) {
            // react to editingItem changes without using the deprecated onChange API
            if editingItem == nil { selectedItemID = nil }
        }
        .sheet(isPresented: $showingAbout) {
            NavigationStack { AboutView(onDone: { showingAbout = false }) }
        }
        .fullScreenCover(isPresented: $showingAddItem) {
            NavigationStack { AddFridgeItemView(isPresented: $showingAddItem).environment(\.modelContext, modelContext) }
        }
        .sheet(isPresented: $showingWizard) {
            FridgeWizardView(onComplete: { showingWizard = false })
        }
        .fullScreenCover(item: $editingItem) { item in
            NavigationStack {
                EditFridgeItemView(item: item, isPresented: Binding(get: { editingItem != nil }, set: { v in if !v { editingItem = nil } })).environment(\.modelContext, modelContext)
            }
        }
        .fullScreenCover(isPresented: $showingSettings) {
            NavigationStack { FridgeSettingsView(onDone: { showingSettings = false }).environment(\.modelContext, modelContext) }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) { itemsLoaded = true }
        }
        // Email prompt sheet: ask for recipient and then try to present MFMailComposeViewController
        .sheet(isPresented: $showingEmailPrompt) {
            EmailPromptView(email: $emailAddress) { addr in
                // prepare recipients
                mailRecipients = [addr]
                // If device can send mail via MFMailComposeViewController, present it, otherwise fall back to mailto: URL
                if MFMailComposeViewController.canSendMail() {
                    showingMailComposer = true
                } else {
                    let subject = "Groceries"
                    let bodyEncoded = mailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Groceries"
                    if let url = URL(string: "mailto:\(addr)?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .sheet(isPresented: $showingMailComposer) {
            MailComposeView(recipients: mailRecipients, subject: "Groceries", body: mailBody) { result in
                mailResult = result
                showingMailComposer = false
            }
        }
        // System share sheet
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [composeEmailBody()])
        }
    }

    // MARK: - Sidebar
    @ViewBuilder
    private var sidebar: some View {
        NavigationStack {
            VStack {
                if items.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Text("No Fridge Items yet").font(.title2).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
                        Text("Tap + to add a new item or use the wizard to set up a fridge.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)

                        Button("Create Fridge") { showingWizard = true }
                            .buttonStyle(.borderedProminent)
                            .padding(.horizontal)

                        Spacer()
                    }
                } else {
                    List {
                        let groups = groupedSections()
                        ForEach(groups.indices, id: \.self) { gi in
                            let g = groups[gi]
                            Section(header: Text(g.fridge.name)) {
                                ForEach(g.sections.indices, id: \.self) { si in
                                    let s = g.sections[si]
                                    if !s.items.isEmpty {
                                        Text(s.header).font(.subheadline).foregroundStyle(.secondary)
                                        ForEach(s.items) { item in
                                            Button(action: { editingItem = item }) {
                                                itemRow(item)
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityHint("Edit item")
                                        }
                                        .onDelete { offsets in
                                            let toDelete = offsets.map { s.items[$0] }
                                            for it in toDelete { modelContext.delete(it) }
                                            try? modelContext.save()
                                        }
                                    }
                                }
                            }
                        }

                        let orphaned = orphanedItems()
                        if !orphaned.isEmpty {
                            Section(header: Text("Unassigned Items")) {
                                ForEach(orphaned) { item in
                                    Button(action: { editingItem = item }) { itemRow(item) }
                                        .buttonStyle(.plain)
                                        .accessibilityHint("Edit item")
                                }
                                 .onDelete(perform: deleteItems)
                             }
                         }
                     }
                     .listStyle(.insetGrouped)
                     .opacity(itemsLoaded ? 1 : 0)
                 }
             }
             .navigationTitle("Fridge Manager")
             .toolbar {
                 // Keep the menu as a leading toolbar item
                 ToolbarItem(placement: .navigationBarLeading) {
                     Menu {
                         Button { showingWizard = true } label: {
                             HStack(spacing: 10) {
                                 ZStack { Circle().fill(Color.green).frame(width: 28, height: 28); Image(systemName: "plus").foregroundColor(.white).font(.system(size: 14, weight: .bold)) }
                                 Text("Create a fridge")
                             }
                         }

                         Button { showingSettings = true } label: {
                             HStack(spacing: 10) {
                                 ZStack { Circle().fill(Color.gray.opacity(0.6)).frame(width: 28, height: 28); Image(systemName: "gearshape.fill").foregroundColor(.white).font(.system(size: 14)) }
                                 Text("Settings")
                             }
                         }

                         Button { showingAbout = true } label: {
                             HStack(spacing: 10) {
                                 ZStack { Circle().fill(Color.blue).frame(width: 28, height: 28); Image(systemName: "questionmark").foregroundColor(.white).font(.system(size: 14, weight: .semibold)) }
                                 Text("About")
                             }
                         }
                     } label: { Image(systemName: "line.3.horizontal").imageScale(.large) }
                 }

                 // Put the actions in the principal area as separate controls inside an HStack so they appear as individual buttons and are less likely to overflow into the three-dots menu.
                 ToolbarItem(placement: .principal) {
                     HStack(spacing: 16) {
                         Toggle(isOn: $showExpiringOnly) { Image(systemName: showExpiringOnly ? "exclamationmark.circle.fill" : "exclamationmark.circle") }
                             .labelsHidden()

                         Button(action: { mailBody = composeEmailBody(); showingEmailPrompt = true }) { Image(systemName: "envelope.fill") }
                             .accessibilityLabel("Send mail for groceries")

                         Button(action: { showingAddItem = true }) { Image(systemName: "plus") }
                             .accessibilityLabel("Add item")

                         EditButton().disabled(items.isEmpty)

                         Button(action: { mailBody = composeEmailBody(); showingShareSheet = true }) { Image(systemName: "square.and.arrow.up") }
                             .accessibilityLabel("Share content view")
                     }
                 }
             }
         }
     }

    // MARK: - Detail
    @ViewBuilder
    private var detail: some View {
        if let id = selectedItemID, let selected = items.first(where: { $0.id == id }) {
            itemDetailView(item: selected)
        } else {
            Text("Select an item").foregroundStyle(.secondary)
        }
    }

    // Small detail view used in navigation links and detail area
    @ViewBuilder
    private func itemDetailView(item: FridgeItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.productName.isEmpty ? "Unnamed product" : item.productName).font(.title2)
                Text(item.locationDisplay).foregroundStyle(.secondary)
                Text("Added: \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))").foregroundStyle(.secondary)
                Text("Expires: \(item.expirationDate, format: Date.FormatStyle(date: .numeric))").foregroundStyle(.secondary)

                Button("Edit") { editingItem = item }
                    .buttonStyle(.bordered)
                    .padding(.top, 8)
            }
            .padding()
        }
    }

    // MARK: - Helpers
    private func deleteItems(offsets: IndexSet) {
        for i in offsets { let item = items[i]; modelContext.delete(item) }
        try? modelContext.save()
    }

    private func itemRow(_ item: FridgeItem) -> some View {
        HStack(spacing: 12) {
            if let status = expirationStatus(for: item) {
                if let bg = status.bgColor {
                    ZStack {
                        Circle().fill(bg).frame(width: 28, height: 28)
                        Image(systemName: status.name).foregroundColor(status.color)
                    }
                } else {
                    Image(systemName: status.name).foregroundColor(status.color)
                }
            }

            // determine color for the expiration date text to match the status icon
            let dateColor: Color = {
                if let status = expirationStatus(for: item) {
                    return status.color
                }
                return Color.secondary
            }()

            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName.isEmpty ? "(No name)" : item.productName).font(.headline)
                HStack(spacing: 8) {
                    Text(item.locationDisplay).font(.subheadline).foregroundStyle(.secondary)
                    Spacer()

                    // If expired show 'Expired' label in grey, otherwise show formatted date — color matches status
                    if let _ = expirationStatus(for: item), item.expirationDate < Date() {
                        Text("Expired since \(item.expirationDate, format: Date.FormatStyle(date: .numeric))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        Text("Expires: \(item.expirationDate, format: Date.FormatStyle(date: .numeric))")
                            .font(.subheadline)
                            .foregroundColor(dateColor)
                    }
                }
            }

            Spacer()

            // thumbnail on the trailing edge
            if let data = item.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill().frame(width: 48, height: 48).clipped().cornerRadius(6)
            }
        }
    }

    private func expirationStatus(for item: FridgeItem) -> (name: String, color: Color, bgColor: Color?, accessibilityLabel: String)? {
        let now = Date()
        // expired items
        if item.expirationDate < now {
            // expired > 3 days -> show trash icon with red background
            if let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now), item.expirationDate <= threeDaysAgo {
                return ("trash.fill", .white, .red, "Expired more than 3 days")
            }
            // expired but within last 3 days
            return ("xmark.octagon.fill", .red, nil, "Expired")
        }
        // expires tomorrow
        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: now), item.expirationDate <= nextDay {
            return ("exclamationmark.triangle.fill", .red, nil, "Expires tomorrow")
        }
        // expires within 2 days
        if let twoDays = Calendar.current.date(byAdding: .day, value: 2, to: now), item.expirationDate <= twoDays {
            return ("exclamationmark.circle.fill", .orange, nil, "Expires within 2 days")
        }
        // default (far future)
        return ("checkmark.circle.fill", .green, nil, "Expires later")
    }

    private func isExpiringWithinTwoDays(_ item: FridgeItem) -> Bool {
        guard let twoDays = Calendar.current.date(byAdding: .day, value: 2, to: Date()) else { return false }
        return item.expirationDate <= twoDays
    }

    private func groupedSections() -> [(fridge: Fridge, sections: [(header: String, items: [FridgeItem])])] {
        var result: [(Fridge, [(String, [FridgeItem])])] = []
        for fridge in fridges {
            var subsections: [(String, [FridgeItem])] = []
            let itemsInFridge = items.filter { item in
                if let s = item.shelf { return fridge.shelves.contains(where: { $0.id == s.id }) }
                if let d = item.drawer { return fridge.drawers.contains(where: { $0.id == d.id }) }
                return false
            }

            for shelf in fridge.shelves {
                var itemsForShelf = itemsInFridge.filter { $0.shelf?.id == shelf.id }
                if showExpiringOnly { itemsForShelf = itemsForShelf.filter { isExpiringWithinTwoDays($0) } }
                itemsForShelf.sort { $0.expirationDate > $1.expirationDate }
                if !itemsForShelf.isEmpty { subsections.append((shelf.name, itemsForShelf)) }
            }
            for drawer in fridge.drawers {
                var itemsForDrawer = itemsInFridge.filter { $0.drawer?.id == drawer.id }
                if showExpiringOnly { itemsForDrawer = itemsForDrawer.filter { isExpiringWithinTwoDays($0) } }
                itemsForDrawer.sort { $0.expirationDate > $1.expirationDate }
                if !itemsForDrawer.isEmpty { subsections.append((drawer.name, itemsForDrawer)) }
            }

            var unassigned = itemsInFridge.filter { $0.shelf == nil && $0.drawer == nil }
            if showExpiringOnly { unassigned = unassigned.filter { isExpiringWithinTwoDays($0) } }
            unassigned.sort { $0.expirationDate > $1.expirationDate }
            if !unassigned.isEmpty { subsections.append(("Unassigned", unassigned)) }

            if !subsections.isEmpty { result.append((fridge, subsections)) }
        }
        return result.map { (fridge: $0.0, sections: $0.1.map { (header: $0.0, items: $0.1) }) }
    }

    private func orphanedItems() -> [FridgeItem] {
        var list = items.filter { $0.shelf == nil && $0.drawer == nil }
        if showExpiringOnly { list = list.filter { isExpiringWithinTwoDays($0) } }
        list.sort { $0.expirationDate > $1.expirationDate }
        return list
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FridgeItem.self, Fridge.self, Shelf.self, Drawer.self], inMemory: true)
        .preferredColorScheme(.dark)
}

// Minimal Add Item view (re-added so the symbol is available to ContentView)
struct AddFridgeItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool

    @State private var productName: String = ""
    @State private var expirationDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    @Query private var fridges: [Fridge]

    @State private var selectedFridgeIndex: Int = 0
    @State private var locationType: String = "Shelf"
    @State private var selectedShelfIndex: Int = 0
    @State private var selectedDrawerIndex: Int = 0

    // image picker state
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var pickedImageData: Data? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Product")) {
                    TextField("Product name", text: $productName)
                }
                Section(header: Text("Expiration")) {
                    DatePicker("Expiration date", selection: $expirationDate, displayedComponents: .date)
                }
                Section(header: Text("Fridge / Location")) {
                    if fridges.isEmpty {
                        Text("No fridges configured. Use the wizard to create one.").foregroundStyle(.secondary)
                    } else {
                        Picker("Fridge", selection: $selectedFridgeIndex) { ForEach(fridges.indices, id: \.self) { idx in Text(fridges[idx].name).tag(idx) } }
                        Picker("Location Type", selection: $locationType) { Text("Shelf").tag("Shelf"); Text("Drawer").tag("Drawer") }.pickerStyle(.segmented)
                        if locationType == "Shelf" {
                            if fridges[selectedFridgeIndex].shelves.isEmpty { Text("No shelves").foregroundStyle(.secondary) }
                            else { Picker("Shelf", selection: $selectedShelfIndex) { ForEach(fridges[selectedFridgeIndex].shelves.indices, id: \.self) { idx in Text(fridges[selectedFridgeIndex].shelves[idx].name).tag(idx) } } }
                        } else {
                            if fridges[selectedFridgeIndex].drawers.isEmpty { Text("No drawers").foregroundStyle(.secondary) }
                            else { Picker("Drawer", selection: $selectedDrawerIndex) { ForEach(fridges[selectedFridgeIndex].drawers.indices, id: \.self) { idx in Text(fridges[selectedFridgeIndex].drawers[idx].name).tag(idx) } } }
                        }
                    }
                }

                // Image picker
                Section(header: Text("Photo")) {
                    HStack(spacing: 12) {
                        if let data = pickedImageData, let ui = UIImage(data: data) {
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

                            if pickedImageData != nil {
                                Button("Clear Photo", role: .destructive) { pickedImageData = nil }
                            }
                        }
                    }
                }

                Section {
                    Button("Save") {
                        var shelf: Shelf? = nil
                        var drawer: Drawer? = nil
                        if !fridges.isEmpty {
                            let fridge = fridges[selectedFridgeIndex]
                            if locationType == "Shelf", fridge.shelves.indices.contains(selectedShelfIndex) { shelf = fridge.shelves[selectedShelfIndex] }
                            if locationType == "Drawer", fridge.drawers.indices.contains(selectedDrawerIndex) { drawer = fridge.drawers[selectedDrawerIndex] }
                        }
                        let newItem = FridgeItem(timestamp: Date(), productName: productName, expirationDate: expirationDate, shelf: shelf, drawer: drawer, imageData: pickedImageData)
                        modelContext.insert(newItem)
                        do { try modelContext.save(); isPresented = false } catch { print("Failed to save item: \(error)") }
                    }
                    Button("Cancel", role: .cancel) { isPresented = false }
                }
            }
            .navigationTitle("Add Item")
        }
    }
}

// Compose the email body from the current filter (uses showExpiringOnly to filter items)
extension ContentView {
    private func filteredItemsForEmail() -> [FridgeItem] {
        if showExpiringOnly {
            return items.filter { isExpiringWithinTwoDays($0) }
        }
        return items
    }

    private func composeEmailBody() -> String {
        // When a filter is active we only include filtered items; otherwise include everything as presented in ContentView.
        let df = Date.FormatStyle(date: .numeric)
        let dfWithTime = Date.FormatStyle(date: .numeric, time: .shortened)

        // Build grouped output: fridge -> section (shelf/drawer/unassigned) -> items
        var outputLines: [String] = []

        // We will respect the showExpiringOnly filter by using the groupedSections() logic, which already filters when needed.
        let groups = groupedSections()
        if groups.isEmpty {
            // No grouped items, but maybe there are orphaned/unassigned items or nothing at all
            let fallback = filteredItemsForEmail()
            if fallback.isEmpty { return "No items match the current filter." }
            for it in fallback {
                var location = "Unassigned"
                if let shelf = it.shelf { location = "Shelf: \(shelf.name)" }
                else if let drawer = it.drawer { location = "Drawer: \(drawer.name)" }
                let line = "Product: \(it.productName.isEmpty ? "(No name)" : it.productName) | \(location) | Expires: \(it.expirationDate.formatted(df))"
                outputLines.append(line)
            }
            return outputLines.joined(separator: "\n")
        }

        for g in groups {
            outputLines.append("Fridge: \(g.fridge.name)")
            for section in g.sections {
                outputLines.append("  \(section.header):")
                let itemsInSection = section.items
                if itemsInSection.isEmpty {
                    outputLines.append("    (no items)")
                } else {
                    for it in itemsInSection {
                        let name = it.productName.isEmpty ? "(No name)" : it.productName
                        let expires = it.expirationDate.formatted(df)
                        let added = it.timestamp.formatted(dfWithTime)
                        var location = ""
                        if let s = it.shelf { location = "Shelf: \(s.name)" }
                        else if let d = it.drawer { location = "Drawer: \(d.name)" }
                        let line = "    - \(name) | \(location.isEmpty ? "Unassigned" : location) | Expires: \(expires) | Added: \(added)"
                        outputLines.append(line)
                    }
                }
            }
            outputLines.append("")
        }

        return outputLines.joined(separator: "\n")
    }
}

// MARK: - Mail composer wrapper
struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    let completion: (Result<MFMailComposeResult, Error>) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        init(_ parent: MailComposeView) { self.parent = parent }
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error { parent.completion(.failure(error)) }
            else { parent.completion(.success(result)) }
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Share sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // no-op
    }
}

// MARK: - Email prompt sheet
struct EmailPromptView: View {
    @Binding var email: String
    var onSend: (String) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Recipient")) {
                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
                Section {
                    Button("Send") {
                        onSend(email)
                        dismiss()
                    }
                    .disabled(!isValidEmail(email))

                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            .navigationTitle("Send groceries")
        }
    }

    private func isValidEmail(_ s: String) -> Bool {
        // Simple regex validation
        let pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        let pred = NSPredicate(format: "SELF MATCHES[c] %@", pattern)
        return pred.evaluate(with: s)
    }
}
