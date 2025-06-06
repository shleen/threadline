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
    @State private var showCategoryPicker: Bool = false // State for showing category picker
    @State private var categories: [String] = []
    var body: some View {
        NavigationView {
            ZStack {
                Color.background.edgesIgnoringSafeArea(.all)

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                } else if showError || outfits.isEmpty {
                    ErrorView(showError: $showError, fetchOutfits: refetchOutfits)
                } else {
                    VStack {
                        let selectedOutfit = outfits[currentIndex]

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(selectedOutfit.clothes) { item in
                                    ZStack(alignment: .topLeading) {
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
                                        
                                        // Add a button to remove the clothing item
                                        Button(action: {
                                            removeItem(item)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                                .padding(8)
                                                .background(Color.white)
                                                .clipShape(Circle())
                                                .shadow(radius: 2)
                                        }
                                        .padding(5) // Position the button at the top-left corner
                                    }
                                }
                            }
                        }

                        // Add Item Button
                        Button(action: {
                            showCategoryPicker = true // Show the category picker
                        }) {
                            Text("Add Item")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.orange)
                                .cornerRadius(10)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 10)
                        .confirmationDialog("Select a Category", isPresented: $showCategoryPicker) {
                            ForEach(categories, id: \.self) { category in
                                Button(category) {
                                    categoryToSwap = category // Set the selected category
                                    itemToSwap = nil // Indicate that we're adding a new item
                                    isSwapViewPresented = true // Show the SwapItemView
                                }
                            }
                        } message: {
                            Text("Choose a category to add an item")
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
                            .padding(.top, 10)

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
                    if itemToSwap == nil {
                        // Add a new item
                        addItem(newItem: newItem)
                    } else {
                        // Replace an existing item
                        swapItem(newItem: newItem)
                    }
                })
            }
            .onAppear {
                fetchCategories()
            }
        }
    }

    func fetchCategories() {
        guard let url = URL(string: "\(urlStore.serverUrl)/categories/get") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching categories: \(error)")
                return
            }
            
            guard let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    DispatchQueue.main.async {
                        self.categories = json["type"] as? [String] ?? []
                    }
                }
            } catch {
                print("Error decoding categories JSON: \(error)")
            }
        }.resume()
    }

    func addItem(newItem: ClothingItem) {
        outfits[currentIndex].clothes.append(newItem)
    }

    func removeItem(_ item: ClothingItem) {
        if let index = outfits[currentIndex].clothes.firstIndex(where: { $0.id == item.id }) {
            outfits[currentIndex].clothes.remove(at: index)
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

        var multipart = MultipartRequest()
        multipart.add(key: "username", value: username)
        multipart.add(key: "clothing_ids", value: Array(selectedOutfit.clothes).map { String($0.id) }.joined(separator: ","))

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(multipart.httpContentTypeHeadeValue, forHTTPHeaderField: "Content-Type")
        request.httpBody = multipart.httpBody

        // Send confirmed outfit to the server
        Task(priority: .background) {
            let (data, response) = try await URLSession.shared.data(for: request)

            isOutfitConfirmed = true
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("/outfit/post: HTTP STATUS: \(httpStatus.statusCode)")
                return
            }
        }
    }
    
    func swapItem(newItem: ClothingItem) {
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
