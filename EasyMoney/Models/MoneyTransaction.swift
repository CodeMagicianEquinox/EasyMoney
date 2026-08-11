//
//  MoneyTransaction.swift
//  EasyMoney
//
//  Created by Tim Terrance on 8/11/26.
//
import Foundation
import SwiftData

@Model
final class MoneyTransaction {
    var id: UUID
    var title: String
    var amount: Double
    var date: Date
    var category: String
    var isIncome: Bool

    init(
        id: UUID = UUID(), // Transaction identifier
        title: String,
        amount: Double,
        date: Date = Date(),
        category: String,
        isIncome: Bool // Income or Expense
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.isIncome = isIncome
    }
}
