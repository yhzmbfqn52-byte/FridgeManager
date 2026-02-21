//
//  FridgeItem.swift
//  FridgeManager
//
//  Created by Filip Herman on 19/02/2026.
//

import Foundation
import SwiftData

@Model
final class FridgeItem: Identifiable {
    // Unique identifier so SwiftUI's sheet(item:) and ForEach can identify instances safely.
    var id: UUID = UUID()
    var timestamp: Date
    var productName: String
    var expirationDate: Date

    // relationships to Shelf or Drawer
    var shelf: Shelf?
    var drawer: Drawer?

    // optional image stored as Data
    var imageData: Data?

    init(timestamp: Date = Date(), productName: String = "", expirationDate: Date = Date(), shelf: Shelf? = nil, drawer: Drawer? = nil, imageData: Data? = nil) {
        self.timestamp = timestamp
        self.productName = productName
        self.expirationDate = expirationDate
        self.shelf = shelf
        self.drawer = drawer
        self.imageData = imageData
    }

    var locationDisplay: String {
        if let shelf = shelf { return "Shelf: \(shelf.name)" }
        if let drawer = drawer { return "Drawer: \(drawer.name)" }
        return "Unassigned"
    }
}
