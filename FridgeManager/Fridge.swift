import Foundation
import SwiftData

@Model
final class Fridge {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var type: String
    var createdAt: Date = Date()

    // collections
    var shelves: [Shelf] = []
    var drawers: [Drawer] = []

    init(name: String, type: String, shelves: [Shelf] = [], drawers: [Drawer] = []) {
        self.name = name
        self.type = type
        self.shelves = shelves
        self.drawers = drawers
    }
}
