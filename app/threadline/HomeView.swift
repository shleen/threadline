////
////  HomeView.swift
////  threadline
////
////  Created by sheline on 1/27/25.
////

import SwiftUI

struct HomeView: View {
    @AppStorage("username") private var username: String = ""

    @State private var outfits: [Outfit] = []
    @State private var currentIndex: Int = 0

    @ObservedObject private var locationManager = LocationManager.shared

    @State private var isPresentingLogOutfitView: Bool = false
    @State private var isPresentingWardrobeView: Bool = false
    @State private var selectedTab: Int = 0

    private func logout() {
        username = ""
    }

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
        }
        .onAppear {
            // Eagerly request location to reduce latency in GenerateView
            locationManager.requestLocation()
        }
    }

    var mainContent: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading) {
                                HStack(alignment: .center) {
                                    Text("Looking good, \(username)")
                                        .font(.system(size: 18, weight: .medium))

                                    Spacer()

                                    Button(action: logout) {
                                        Text("Logout")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.top, 40)
                                .padding(.bottom, 2)

                                Text("Tell us what you're wearing - we'll use it to show you stats and recommend new outfits.")
                                    .font(.system(size: 14, weight: .light))
                                    .padding(.bottom, 6)
                                Button(action: { isPresentingLogOutfitView.toggle() }) {
                                    Text("Log an outfit")
                                        .font(.system(size: 18, weight: .regular))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }

                        HomeInspirationView(outfits: $outfits, currentIndex: $currentIndex)
                            .padding(.top, 8)

                        VStack {
                            Button(action: { isPresentingWardrobeView.toggle() }) {
                                Text("Browse your wardrobe")
                                    .font(.system(size: 18, weight: .regular))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.vertical, 15)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Shows recently worn outfits from other users
                    FeedView()

                    // Prevents background color from bleeding into the tab bar
                    Spacer()
                    Rectangle()
                        .frame(height: 0)
                        .background(.bar)
                }
            }
            .background(Color.background)
            .frame(maxHeight: .infinity)
            .navigationDestination(isPresented: $isPresentingLogOutfitView) {
                LogOutfitView(isPresented: $isPresentingLogOutfitView, items: [])
            }
            .navigationDestination(isPresented: $isPresentingWardrobeView) {
                WardrobeView()
            }
        }
    }
}

struct HomeInspirationView: View {
    @AppStorage("username") private var username: String = ""

    @Binding var outfits: [Outfit]
    @Binding var currentIndex: Int

    @Environment(UrlStore.self) private var urlStore

    @ObservedObject private var locationManager = LocationManager.shared

    @State private var isLoading: Bool = false
    @State private var isPresentingGenerateView: Bool = false
    @State private var showError: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Need inspiration?")
                .font(.system(size: 16, weight: .medium))
            Text("Try something ✨new, or go for something you already know and love.")
                .font(.system(size: 12, weight: .light))
                .fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if isLoading {
                        LoadingFrameView()
                    } else {
                        ForEach(Array(outfits.prefix(3).enumerated()), id: \.element) { index, outfit in
                            OutfitFrameView(
                                index: index,
                                currentIndex: $currentIndex,
                                isPresentingGenerateView: $isPresentingGenerateView,
                                isGenerated: .constant(true),
                                clothes: outfit.clothes
                            )
                        }
                    }

                    // TODO: Add OutfitFrameView for some past outfitts.
                    // Set isGenerated to false, and index doesn't matter.
                    // OutfitFrameView(
                    //     index: -1,
                    //     currentIndex: $currentIndex,
                    //     isPresentingGenerateView: $isPresentingGenerateView,
                    //     isGenerated: .constant(false),
                    //     clothes: []
                    // )
                }
            }.padding(.top, 8)

        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(9)
        .padding(.vertical, 8)
        .shadow(color: Color.gray.opacity(0.5), radius: 4, x: 0, y: 2)
        .onAppear {
            // Fetch recommendations
            fetchOutfits()
        }
        .navigationDestination(isPresented: $isPresentingGenerateView) {
            GenerateView(outfits: $outfits, currentIndex: $currentIndex, refetchOutfits: fetchOutfits)
        }
    }

    func fetchOutfits() {
        isLoading = true
        showError = false

        locationManager.requestLocation { location in
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude

            guard let url = URL(string: "\(urlStore.serverUrl)/recommendation/get?username=\(username)&lat=\(lat)&lon=\(lon)") else {
                print("Invalid URL")
                DispatchQueue.main.async {
                    isLoading = false
                    showError = true
                }
                return
            }

            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error fetching outfits: \(error)")
                        showError = true
                        return
                    }

                    if let data = data {
                        do {
                            let decodedResponse = try JSONDecoder().decode([String: [Outfit]].self, from: data)
                            if let fetchedOutfits = decodedResponse["outfits"], !fetchedOutfits.isEmpty {
                                self.outfits = fetchedOutfits
                                self.currentIndex = 0
                                printOutfits(outfits: fetchedOutfits)

                                isLoading = false
                            } else {
                                showError = true
                            }
                        } catch {
                            print("Error decoding JSON: \(error)")
                            showError = true
                        }
                    } else {
                        showError = true
                    }
                }
            }.resume()
        }
    }

    func printOutfits(outfits: [Outfit]) {
        for (index, outfit) in outfits.enumerated() {
            print("Outfit \(index + 1):")
            print("  \(outfit.clothes.map { $0.img })")
        }
    }
}

struct LoadingFrameView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Generating fresh outfits for you. Hold tight!")
                .font(.system(size: 12, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        }
        .frame(width: 120, height: 180)
        .padding(8)
        .background(Color.background)
        .cornerRadius(8)
    }
}

struct OutfitFrameView: View {
    let index: Int

    @Binding var currentIndex: Int
    @Binding var isPresentingGenerateView: Bool
    @Binding var isGenerated: Bool
    let clothes: [ClothingItem]

    @Environment(UrlStore.self) private var urlStore

    var body: some View {
        VStack(alignment: .leading) {
            Text("✨ Created for you")
                .font(.system(size: 10, weight: .light))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.white)
                .cornerRadius(4)
                .opacity(isGenerated ? 1 : 0)

            // Calculate grid layout based on number of items
            let columns = Array(repeating: GridItem(.flexible()), count: min(clothes.count, 2))

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(clothes) { item in
                    AsyncImage(url: URL(string: "\(urlStore.r2BucketUrl)\(item.img)")) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else if phase.error != nil {
                            // display an error placeholder
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.gray)
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(width: 58, height: 78) // Adjusted size to fit 2x2 grid in 120x160 frame
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .frame(width: 120, height: 160)
            .background(Color.background)
            .cornerRadius(8)
        }
        .onTapGesture {
            if isGenerated {
                currentIndex = index
                isPresentingGenerateView.toggle()
            } else {
                // TODO: Go to previous outfit view
            }
        }
        .padding(8)
        .background(Color.background)
        .cornerRadius(8)
    }
}
