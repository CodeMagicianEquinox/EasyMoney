//
//  EasyMoneyApp.swift
//  EasyMoney
//
//  Created by Tim Terrance on 8/4/26.
//

import SwiftUI
import SwiftData

@main
struct EasyMoneyApp: App {
    @AppStorage("seenWelcomeView") private var seenWelcomeView: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if !seenWelcomeView {
                OnboardingView()
            } else {
                ContentView()
            }
        }
        .modelContainer(for: [User.self, MoneyTransaction.self])
    }
}
