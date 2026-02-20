import Foundation
import SwiftData

@Model
final class Fridge {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var type: String
    var shelfCount: Int
    var createdAt: Date = Date()

    init(name: String, type: String, shelfCount: Int) {
        self.name = name
        self.type = type
        self.shelfCount = shelfCount
    }
}
