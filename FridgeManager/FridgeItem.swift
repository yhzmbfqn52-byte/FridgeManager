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

    init(timestamp: Date = Date(), productName: String = "", expirationDate: Date = Date()) {
        self.timestamp = timestamp
        self.productName = productName
        self.expirationDate = expirationDate
    }
}
