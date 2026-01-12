//
//  Item.swift
//  ZenHabits
//
//  Created by EREN BODUR on 12.01.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
