//
//  FridgeItem.swift
//  FridgeManager
//
//  Created by Filip Herman on 19/02/2026.
//

import Foundation
import SwiftData

@Model
final class FridgeItem {
    var timestamp: Date
    var productName: String
    var expirationDate: Date

    // location: either shelfId or drawerId (one of them may be nil)
    var shelfId: UUID?
    var drawerId: UUID?

    init(timestamp: Date = Date(), productName: String = "", expirationDate: Date = Date(), shelfId: UUID? = nil, drawerId: UUID? = nil) {
        self.timestamp = timestamp
        self.productName = productName
        self.expirationDate = expirationDate
        self.shelfId = shelfId
        self.drawerId = drawerId
    }

    var locationDisplay: String {
        if let sid = shelfId { return "Shelf: \(sid.uuidString.prefix(6))" }
        if let did = drawerId { return "Drawer: \(did.uuidString.prefix(6))" }
        return "Unassigned"
    }
}
