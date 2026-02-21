import XCTest
import SwiftData
@testable import FridgeManager

@MainActor
final class FridgeItemTests: XCTestCase {
    func testAddItemWithShelfAssociation() throws {
        let schema = Schema([Fridge.self, Shelf.self, Drawer.self, FridgeItem.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let context = container.mainContext

        // Create fridge with one shelf
        let shelf = Shelf(name: "Top Shelf", position: 1)
        let fridge = Fridge(name: "TestFridge", type: "Standard", shelves: [shelf], drawers: [])
        context.insert(fridge)
        try context.save()

        // Add item assigned to the shelf (use relationship)
        let item = FridgeItem(timestamp: Date(), productName: "Milk", expirationDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!, shelf: shelf, drawer: nil)
        context.insert(item)
        try context.save()

        // Fetch items and verify using FetchDescriptor
        let items = try context.fetch(FetchDescriptor<FridgeItem>())
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.productName, "Milk")
        XCTAssertNotNil(items.first?.shelf)
        XCTAssertEqual(items.first?.shelf?.name, shelf.name)
    }
}
