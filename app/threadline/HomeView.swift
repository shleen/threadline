//
//  HomeView.swift
//  threadline
//
//  Created by sheline on 1/27/25.
//

import SwiftUI

struct HomeView: View {
    @AppStorage("username") private var username: String = ""

    @State private var isPresentingLogOutfitView: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Looking good, \(username)")
                .font(.system(size: 16, weight: .medium))
            Text("Tell us what you’re wearing - we’ll use it to show you stats and recommend new outfits.")
                .font(.system(size: 12, weight: .light))
            Button(action: { isPresentingLogOutfitView.toggle() }) {
                Text("Log an outfit")
                    .font(.system(size: 16, weight: .regular))
                    // Note that call to .frame must come before the call to .buttonStyle for the
                    // button to actually fill the entire width of the screen
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .navigationDestination(isPresented: $isPresentingLogOutfitView) {
            LogOutfitView(isPresented: $isPresentingLogOutfitView)
        }
    }
}
