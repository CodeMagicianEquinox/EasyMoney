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
    @AppStorage("userId") private var userId: String = ""
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            // list here the rest of models
            MoneyTransaction.self,
        ])
        
        do {
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            let context = container.mainContext
            return container
        } catch {
            fatalError("Error setting up SwiftData: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            if !seenWelcomeView {
                OnboardingView()
            } else {
                if userId.isEmpty {
                    // no user logged in
                    NavigationStack {
                        LoginView()
                    }
                }
                else {
                    // already logged in
                    ContentView()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
