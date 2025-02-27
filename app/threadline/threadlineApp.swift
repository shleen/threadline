//
//  threadlineApp.swift
//  threadline
//
//  Created by sheline on 1/27/25.
//

import SwiftUI

@main
struct threadlineApp: App {
    @AppStorage("username") private var username: String = ""

    var body: some Scene {
        WindowGroup {
            // Check if username has been set. If yes, proceed to home
            // page per usual. If not, navigate to SetupView to
            // prompt user for a username.
            if (username.isEmpty) {
                SetupView()
            }
            else {
                NavigationStack {
                    HomeView()
                }
            }
        }
    }
}
