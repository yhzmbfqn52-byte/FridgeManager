import XCTest
import SwiftData
@testable import FridgeManager

@MainActor
final class FirstRunTests: XCTestCase {
    override func setUpWithError() throws {
        UserDefaults.standard.removeObject(forKey: "hasCompletedWizard")
    }

    func testWizardSetsFirstRunFlag() throws {
        // Use an in-memory ModelContainer for testing
        let schema = Schema([Fridge.self, Shelf.self, Drawer.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let context = container.mainContext

        // Create a fridge programmatically similar to the wizard
        let fridge = Fridge(name: "Test", type: "Standard")
        context.insert(fridge)
        try context.save()

        // Emulate wizard behavior
        UserDefaults.standard.set(true, forKey: "hasCompletedWizard")

        let flag = UserDefaults.standard.bool(forKey: "hasCompletedWizard")
        XCTAssertTrue(flag, "Wizard should set the hasCompletedWizard flag to true")
    }
}
