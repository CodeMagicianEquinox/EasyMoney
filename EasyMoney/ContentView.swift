//
//  ContentView.swift
//  EasyMoney
//
//  Created by Tim Terrance on 8/4/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isDemoUserLoggedIn") private var isDemoUserLoggedIn = false

    var body: some View {
        if isDemoUserLoggedIn {
            MainTabView()
        } else {
            NavigationStack {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
}
