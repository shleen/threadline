//
//  GenerateView.swift
//  threadline
//
//  Created by James Choi on 3/15/25.
//

import SwiftUI

struct GenerateView: View {
    @AppStorage("username") private var username: String = ""
    
    @Environment(UrlStore.self) private var urlStore

    @ObservedObject private var locationManager = LocationManager.shared

    @Binding var outfits: [Outfit]
    @Binding var currentIndex: Int
    let refetchOutfits: () -> Void

    @State private var isOutfitConfirmed: Bool = false
    @State private var isSwapViewPresented: Bool = false
    @State private var itemToSwap: ClothingItem?
    @State private var categoryToSwap: String?
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 1.0, green: 0.992, blue: 0.91).edgesIgnoringSafeArea(.all)

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                } else if showError || outfits.isEmpty {
                    ErrorView(showError: $showError, fetchOutfits: refetchOutfits)
                } else {
                    VStack {
                        let selectedOutfit = outfits[currentIndex]
                        let columns = Array(repeating: GridItem(.flexible()), count: selectedOutfit.clothes.count)

                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(selectedOutfit.clothes) { item in
                                VStack {
                                    AsyncImage(url: URL(string: "\(urlStore.r2BucketUrl)\(item.img)")) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 115, height: 115)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        } else {
                                            Color.gray
                                        }
                                    }
                                    Button(action: {
                                        itemToSwap = item
                                        categoryToSwap = item.type
                                        isSwapViewPresented = true
                                    }) {
                                        Image(systemName: "arrow.swap")
                                            .foregroundColor(.blue)
                                            .padding(.bottom, 45)
                                    }
                                }
                            }
                        }
                        
                        if !isOutfitConfirmed {
                            Button(action: {
                                nextOutfit()
                            }) {
                                Text("Next Outfit")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                    .padding(.horizontal, 20)
                            }

                            Button(action: {
                                confirmOutfit()
                            }) {
                                Text("Confirm")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .cornerRadius(10)
                                    .padding(.horizontal, 20)
                            }
                            .padding(.top, 10)
                        } else {
                            Text("Outfit Confirmed")
                                .font(.headline)
                                .foregroundColor(.green)
                                .padding()
                        }
                    }
                    .padding(.bottom, 48)
                    .padding(.top, 50)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 15)
                    .padding(.bottom, 135)
                    .shadow(color: Color.gray.opacity(0.85), radius: 20, x: 0, y:5)
                }
                Spacer()
            }
            .navigationTitle(Text("Your Recommendation"))
            .sheet(isPresented: $isSwapViewPresented) {
                SwapItemView(category: $categoryToSwap, onItemSelected: { newItem in
                    swapItem(newItem: newItem)
                })
            }
        }
    }

    func nextOutfit() {
        guard !outfits.isEmpty else { return }
        currentIndex = (currentIndex + 1) % outfits.count
    }

    func confirmOutfit() {
        let selectedOutfit = outfits[currentIndex]

        print("Outfit:")
        print(selectedOutfit)

        guard let url = URL(string: "\(urlStore.serverUrl)/outfit/post") else {
            print("Invalid URL")
            return
        }

        let payload: [String: Any] = [
            "username": username,
            "clothing_ids": selectedOutfit.clothes.map { $0.id }
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }

        isOutfitConfirmed = true

        // Send confirmed outfit to the server
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending confirmed outfit: \(error)")
                return
            }
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                print("Outfit confirmed successfully")
            } else {
                print("Failed to confirm outfit")
            }
        }.resume()
    }
    
    func swapItem(newItem: ClothingItem) {
        // Replace itemToSwap with newItem in outfits[currentIndex]
        if let item_index = outfits[currentIndex].clothes.firstIndex(where: { $0.id == itemToSwap?.id }) {
            outfits[currentIndex].clothes[item_index] = newItem
        }
    }
}

struct ErrorView: View {
    @Binding var showError: Bool
    @State var fetchOutfits: () -> Void

    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
                .padding()
            Text("Outfit recommendations failed. Please try again later.")
                .multilineTextAlignment(.center)
                .padding()
            Button(action: {
                showError = false
                fetchOutfits()
            }) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
            }
        }
    }
}
