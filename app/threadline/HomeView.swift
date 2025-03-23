////
////  HomeView.swift
////  threadline
////
////  Created by sheline on 1/27/25.
////

import SwiftUI

struct HomeView: View {
    @AppStorage("username") private var username: String = ""

    @State private var isPresentingLogOutfitView: Bool = false
    @State private var isPresentingWardrobeView: Bool = false
    @State private var isPresentingGenerateView: Bool = false
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                mainContent
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
                TagView()
                    .tabItem {
                        Image(systemName: "photo.badge.plus.fill")
                        Text("Create clothing")
                    }
                    .tag(1)

                RecentView()
                    .tabItem {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Recent")
                    }
                    .tag(2)

                // TODO: Replace Text with correct View
                Text("Placeholder 3")
                    .tabItem {
                        Image(systemName: "chart.bar.xaxis")
                        Text("Statistics")
                    }
                    .tag(3)

                // TODO: Replace Text with correct View
                Text("Placeholder 4")
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                    .tag(4)
            }
            
            // Shadow effect at the top of the navbar
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .frame(height: 1)
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: -3)
                .offset(y: -49) // Adjust for tab bar height
        }
    }

    var mainContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Looking good, \(username)")
                .font(.system(size: 16, weight: .medium))
            Text("Tell us what you're wearing - we'll use it to show you stats and recommend new outfits.")
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

            Button(action: { isPresentingWardrobeView.toggle() }) {
                Text("Wardrobe")
                    .font(.system(size: 16, weight: .regular))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
            
            Button(action: {isPresentingGenerateView.toggle() }) {
                Text("Generate an Outfit")
                    .font(.system(size: 16, weight: .regular))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .navigationDestination(isPresented: $isPresentingLogOutfitView) {
            LogOutfitView(isPresented: $isPresentingLogOutfitView, items: [])
        }
        .navigationDestination(isPresented: $isPresentingWardrobeView) {
            WardrobeView()
        }
        .navigationDestination(isPresented: $isPresentingGenerateView) {
            GenerateView()
        }
    }
}
