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
        ZStack {
            Color(red: 1.0, green: 0.992, blue: 0.91).edgesIgnoringSafeArea(.all)
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


                AnalyticsView()
                    .tabItem {
                        Image(systemName: "chart.bar.xaxis")
                        Text("Statistics")
                    }
                    .tag(3)
                DeclutterView()
                    .tabItem {
                        Image(systemName: "trash")
                        Text("Declutter")
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
        ZStack {
            Color(red: 1.0, green: 0.992, blue: 0.91).edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading, spacing: 4) {
                VStack {
                    Text("Looking good, \(username)")
                        .font(.system(size: 18, weight: .medium))
                        .padding(.top, 40)
                    Text("Tell us what you're wearing - we'll use it to show you stats and recommend new outfits.")
                        .font(.system(size: 14, weight: .light))
                        .padding(.bottom, 10)
                        .padding(.top, 4)
                        .padding(.horizontal, 4)
                    Button(action: { isPresentingLogOutfitView.toggle() }) {
                        Text("Log an outfit")
                            .font(.system(size: 18, weight: .regular))
                        // Note that call to .frame must come before the call to .buttonStyle for the
                        // button to actually fill the entire width of the screen
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                }
                
                VStack {
                    Button(action: { isPresentingWardrobeView.toggle() }) {
                        Text("Wardrobe")
                            .font(.system(size: 18, weight: .regular))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                }
                
                VStack {
                    Button(action: {isPresentingGenerateView.toggle() }) {
                        Text("Generate an Outfit")
                            .font(.system(size: 18, weight: .regular))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .padding(.bottom, 30)
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.gray.opacity(0.85), radius: 20, x: 0, y: 5)
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
}
