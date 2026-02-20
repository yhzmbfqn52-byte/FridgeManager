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

    // relationships to Shelf or Drawer
    var shelf: Shelf?
    var drawer: Drawer?

    init(timestamp: Date = Date(), productName: String = "", expirationDate: Date = Date(), shelf: Shelf? = nil, drawer: Drawer? = nil) {
        self.timestamp = timestamp
        self.productName = productName
        self.expirationDate = expirationDate
        self.shelf = shelf
        self.drawer = drawer
    }

    var locationDisplay: String {
        if let shelf = shelf { return "Shelf: \(shelf.name)" }
        if let drawer = drawer { return "Drawer: \(drawer.name)" }
        return "Unassigned"
    }
}
