//
//  SetupView.swift
//  threadline
//
//  Created by sheline on 2/25/25.
//

import SwiftUI

struct SetupView: View {
    @State private var navigateToHome: Bool = false

    @AppStorage("username") private var username: String = ""
    @State private var localUsername = ""
    @State private var validUsername: Bool = true
    
    func validateUsername() {
        // Validate username
        if (localUsername.count < 3 || localUsername.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil) {
            // Username too short, or contains invalid characters. Display error message
            validUsername = false
        }
        else {
            // Username is fine. Save it and navigate to HomeView
            username = localUsername
        }
    }

    var body: some View {
        HStack() {
            VStack(spacing: 10) {
                Text("Hello! Welcome to threadline.")
                    .font(.system(size: 24, weight: .light))
                Text("Please choose a username to get started.")
                    .font(.system(size: 16, weight: .light))
                TextField(
                    "centralpassage",
                    text: $localUsername
                )
                    .onSubmit {
                        validateUsername()
                    }
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding(.top, 10)
                    .textFieldStyle(.roundedBorder)
                Text("Username must contain only alphanumeric characters and have at least 3 characters. Please try again.")
                    .foregroundColor(.red)
                    .opacity(validUsername ? 0 : 1)
                    .font(.system(size: 10, weight: .light))
                HStack() {
                    Spacer()
                    Button(action: validateUsername) {
                        Text("Done")
                    }
                }
            }
        }
        .padding(.horizontal, 30)
    }
}
