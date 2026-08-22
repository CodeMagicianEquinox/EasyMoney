//
//  Category.swift
//  EasyMoney
//
//  Created by Tim Terrance on 8/18/26.
//
import Foundation
import SwiftData

@Model
final class ExpenseCategory {
    var name: String
    var iconName: String
    var createdAt: Date

    init(name: String, iconName: String = "tag.fill", createdAt: Date = .now) {
        self.name = name
        self.iconName = iconName
        self.createdAt = createdAt
    }

    static let defaults: [(name: String, icon: String)] = [
        ("Food", "fork.knife"),
        ("Transport", "car.fill"),
        ("Shopping", "bag.fill"),
        ("Bills", "doc.text.fill"),
        ("Other", "tag.fill")
    ]
}
