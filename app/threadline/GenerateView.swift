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

    @State private var outfits: [Outfit] = []
    @State private var selectedOutfit: Outfit?
    @State private var currentIndex: Int = 0
    @State private var isOutfitConfirmed: Bool = false
    @State private var isSwapViewPresented: Bool = false
    @State private var itemToSwap: ClothingItem?
    @State private var categoryToSwap: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 1.0, green: 0.992, blue: 0.91).edgesIgnoringSafeArea(.all)
                VStack {
                    if let selectedOutfit = selectedOutfit {
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
                                            Image("Example")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 115, height: 115)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    Button(action: {
                                        itemToSwap = item
                                        categoryToSwap = getCategory(for: item)
                                        isSwapViewPresented = true
                                    }) {
                                        Image(systemName: "arrow.swap")
                                            .foregroundColor(.blue)
                                            .padding(.bottom, 45)
                                    }
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
                .onAppear {
                    fetchOutfits()
                }
                .sheet(isPresented: $isSwapViewPresented) {
                    if let category = categoryToSwap {
                        SwapItemView(category: category, onItemSelected: { newItem in
                            swapItem(newItem: newItem)
                        })
                    }
                }
                Spacer()
            }
            .navigationTitle(Text("Your Recommendation"))
            
        }
    }
    
    func fetchOutfits() {
        locationManager.requestLocation { location in
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude

            guard let url = URL(string: "\(urlStore.serverUrl)/recommendation/get?username=\(username)&lat=\(lat)&lon=\(lon)") else {
                print("Invalid URL")
                return
            }

            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        let decodedResponse = try JSONDecoder().decode([String: [Outfit]].self, from: data)
                        if let fetchedOutfits = decodedResponse["outfits"], !fetchedOutfits.isEmpty {
                            DispatchQueue.main.async {
                                self.outfits = fetchedOutfits
                                self.selectedOutfit = fetchedOutfits.first
                                self.currentIndex = 0
                                printOutfits(outfits: fetchedOutfits) // Print the contents of the outfits array
                            }
                        }
                    } catch {
                        print("Error decoding JSON: \(error)")
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

    func nextOutfit() {
        guard !outfits.isEmpty else { return }
        currentIndex = (currentIndex + 1) % outfits.count
        selectedOutfit = outfits[currentIndex]
    }

    func confirmOutfit() {
        if let selectedOutfit = selectedOutfit {
            print("Outfit:")
            print(selectedOutfit)
            
            isOutfitConfirmed = true

            // Send confirmed outfit to the server
            sendConfirmedOutfit(outfit: selectedOutfit)
        }
    }
    
    func sendConfirmedOutfit(outfit: Outfit) {
        guard let url = URL(string: "\(urlStore.serverUrl)/outfit/post") else {
            print("Invalid URL")
            return
        }
        
        let payload: [String: Any] = [
            "username": username,
            "clothing_ids": outfit.clothes.map { $0.id }
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
    
    func getCategory(for item: ClothingItem) -> String? {
        // TODO: backend needs to return category
        return "TOP"
    }
    
    func swapItem(newItem: ClothingItem) {
        // Find selectedOutfit in outfits
        if let outfit_index = outfits.firstIndex(where: { $0 == selectedOutfit }) {
            // Replace itemToSwap with newItem in outfits[index]
            if let item_index = outfits[outfit_index].clothes.firstIndex(where: { $0.id == itemToSwap?.id }) {
                outfits[outfit_index].clothes[item_index] = newItem
            }

            // Update selectedOutfit
            selectedOutfit = outfits[outfit_index]
        }
    }
}
