import Foundation
import SwiftData

@Model
final class Budget {
    @Attribute(.unique) var category: String
    var limit: Double
    var createdAt: Date

    init(category: String, limit: Double, createdAt: Date = .now) {
        self.category = category
        self.limit = limit
        self.createdAt = createdAt
    }
}
