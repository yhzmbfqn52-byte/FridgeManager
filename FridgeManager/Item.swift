//
//  Item.swift
//  FridgeManager
//
//  Created by Filip Herman on 19/02/2026.
//

import Foundation
import SwiftData

@Model
final class FridgeItem {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
