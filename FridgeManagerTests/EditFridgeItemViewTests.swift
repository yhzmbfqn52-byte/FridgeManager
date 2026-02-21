import XCTest
import SwiftUI
import SwiftData
@testable import FridgeManager

@MainActor
final class EditFridgeItemViewTests: XCTestCase {
    func testEditFridgeItemViewSavesChanges() async throws {
        // Arrange: in-memory model container with schema
        let schema = Schema([Fridge.self, Shelf.self, Drawer.self, FridgeItem.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let context = container.mainContext

        // Create a fridge with shelves and drawers
        let shelf = Shelf(name: "Top Shelf", position: 1)
        let drawer = Drawer(name: "Left Drawer", position: 1)
        let fridge = Fridge(name: "TestFridge", type: "Standard", shelves: [shelf], drawers: [drawer])
        context.insert(fridge)
        try context.save()

        // Create an item (unenassigned)
        let item = FridgeItem(timestamp: Date(), productName: "OldName", expirationDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        context.insert(item)
        try context.save()

        // Act: create the view model and populate initial values
        let view = EditFridgeItemView(item: item, isPresented: .constant(true))
        // Attach the model container to the view's environment when the view runs; for the test we call helpers directly.
        view.populateInitialValues()

        // Simulate edits by calling the testable static helper
        let newName = "NewName"
        let newExpiration = Calendar.current.date(byAdding: .day, value: 10, to: Date())!

        // We need the current fridges array from the context; fetch it
        let fridgesFetched = try context.fetch(FetchDescriptor<Fridge>())

        EditFridgeItemView.applyChanges(
            to: item,
            productName: newName,
            expirationDate: newExpiration,
            locationType: "Shelf",
            fridgeIndex: 0,
            shelfIndex: 0,
            drawerIndex: 0,
            fridges: fridgesFetched,
            context: context
        )

        // Assert: fetch the item and inspect changes
        let fetched = try context.fetch(FetchDescriptor<FridgeItem>())
        XCTAssertEqual(fetched.count, 1)
        let fetchedItem = fetched.first!
        XCTAssertEqual(fetchedItem.productName, "NewName")
        // expirationDate equality within 1 second
        XCTAssertEqual(Int(fetchedItem.expirationDate.timeIntervalSince1970), Int(newExpiration.timeIntervalSince1970))
        XCTAssertNotNil(fetchedItem.shelf)
        XCTAssertEqual(fetchedItem.shelf?.name, shelf.name)
    }
}
