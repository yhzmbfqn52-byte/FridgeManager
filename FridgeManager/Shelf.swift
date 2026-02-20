import Foundation
import SwiftData

@Model
final class Shelf {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var position: Int

    init(name: String, position: Int) {
        self.name = name
        self.position = position
    }
}
