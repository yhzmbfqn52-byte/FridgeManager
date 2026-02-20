import Foundation
import SwiftData

@Model
final class Drawer {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var position: Int

    init(name: String, position: Int) {
        self.name = name
        self.position = position
    }
}
