//
//  Expense.swift
//  EasyMoney
//
//  Created by Tim Terrance on 8/18/26.
//

import Foundation
import SwiftData

@Model // @Model tell SwiftData to save instances of Expense
final class Expense {
    var title: String
    var amount: Double
    var date: Date
    var category: String
    var currencyCode: String
    var exchangeRate: Double
    var notes: String

    init( // describes what must be supplied when creating an expense
        title: String,
        amount: Double,
        date: Date = .now,
        category: String,
        currencyCode: String,
        exchangeRate: Double = 1.0,
        notes: String = ""
    ) {
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.currencyCode = currencyCode
        self.exchangeRate = exchangeRate
        self.notes = notes
    }

}
