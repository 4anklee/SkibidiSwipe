//
//  Item.swift
//  swift-swipe-game
//
//  Created by Frank Lee on 3/21/25.
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
