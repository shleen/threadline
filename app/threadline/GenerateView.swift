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
    @State private var outfits: [Outfit] = []
    @State private var selectedOutfit: Outfit?
    @State private var currentIndex: Int = 0
    @State private var isOutfitConfirmed: Bool = false
    @State private var isSwapViewPresented: Bool = false
    @State private var itemToSwap: ClothingItem?
    @State private var categoryToSwap: String?
    
    var body: some View {
        VStack {
            Spacer()
            
            if let selectedOutfit = selectedOutfit {
                let items = getAllItems(from: selectedOutfit)
                let columns = getColumns(for: items.count)
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(items) { item in
                        VStack {
                            AsyncImage(url: URL(string: "\(urlStore.r2BucketUrl)\(item.img)")) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                } else {
                                    Image("Example")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
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
                            }
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
            
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
                        .padding(.horizontal, 40)
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
                        .padding(.horizontal, 40)
                }
            } else {
                Text("Outfit Confirmed")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding()
            }
            
            Spacer()
        }
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
    }
    
    func fetchOutfits() {
        guard let url = URL(string: "\(urlStore.serverUrl)/recommendation/get?username=\(username)") else {
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
    
    func printOutfits(outfits: [Outfit]) {
        for (index, outfit) in outfits.enumerated() {
            print("Outfit \(index + 1):")
            if let tops = outfit.TOP {
                print("  TOP: \(tops.map { $0.img })")
            }
            if let bottoms = outfit.BOTTOM {
                print("  BOTTOM: \(bottoms.map { $0.img })")
            }
            if let outerwears = outfit.OUTERWEAR {
                print("  OUTERWEAR: \(outerwears.map { $0.img })")
            }
            if let dresses = outfit.DRESS {
                print("  DRESS: \(dresses.map { $0.img })")
            }
            if let shoes = outfit.SHOES {
                print("  SHOES: \(shoes.map { $0.img })")
            }
        }
    }

    func nextOutfit() {
        guard !outfits.isEmpty else { return }
        currentIndex = (currentIndex + 1) % outfits.count
        selectedOutfit = outfits[currentIndex]
    }

    func confirmOutfit() {
        isOutfitConfirmed = true
        if let selectedOutfit = selectedOutfit {
            print("Outfit:")
            if let tops = selectedOutfit.TOP {
                print("  TOP: \(tops.map { $0.img })")
            }
            if let bottoms = selectedOutfit.BOTTOM {
                print("  BOTTOM: \(bottoms.map { $0.img })")
            }
            if let outerwears = selectedOutfit.OUTERWEAR {
                print("  OUTERWEAR: \(outerwears.map { $0.img })")
            }
            if let dresses = selectedOutfit.DRESS {
                print("  DRESS: \(dresses.map { $0.img })")
            }
            if let shoes = selectedOutfit.SHOES {
                print("  SHOES: \(shoes.map { $0.img })")
            }
            
            // Send confirmed outfit to the server
            sendConfirmedOutfit(outfit: selectedOutfit)
        }
    }
    
    func sendConfirmedOutfit(outfit: Outfit) {
        guard let url = URL(string: "\(urlStore.serverUrl)/outfit/post") else {
            print("Invalid URL")
            return
        }
        
        var clothingIds: [Int] = []
        if let tops = outfit.TOP { clothingIds.append(contentsOf: tops.map { $0.id }) }
        if let bottoms = outfit.BOTTOM { clothingIds.append(contentsOf: bottoms.map { $0.id }) }
        if let outerwears = outfit.OUTERWEAR { clothingIds.append(contentsOf: outerwears.map { $0.id }) }
        if let dresses = outfit.DRESS { clothingIds.append(contentsOf: dresses.map { $0.id }) }
        if let shoes = outfit.SHOES { clothingIds.append(contentsOf: shoes.map { $0.id }) }
        
        let payload: [String: Any] = [
            "username": username,
            "clothing_ids": clothingIds
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
    
    func getAllItems(from outfit: Outfit) -> [ClothingItem] {
        var items: [ClothingItem] = []
        if let tops = outfit.TOP { items.append(contentsOf: tops) }
        if let bottoms = outfit.BOTTOM { items.append(contentsOf: bottoms) }
        if let outerwears = outfit.OUTERWEAR { items.append(contentsOf: outerwears) }
        if let dresses = outfit.DRESS { items.append(contentsOf: dresses) }
        if let shoes = outfit.SHOES { items.append(contentsOf: shoes) }
        return items
    }
    
    func getColumns(for itemCount: Int) -> [GridItem] {
        switch itemCount {
        case 2:
            return [GridItem(.flexible()), GridItem(.flexible())]
        case 3:
            return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        case 4:
            return [GridItem(.flexible()), GridItem(.flexible())]
        case 5:
            return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        case 6:
            return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        default:
            return [GridItem(.flexible())]
        }
    }
    
    func getCategory(for item: ClothingItem) -> String? {
        if selectedOutfit?.TOP?.contains(where: { $0.id == item.id }) == true {
            return "TOP"
        } else if selectedOutfit?.BOTTOM?.contains(where: { $0.id == item.id }) == true {
            return "BOTTOM"
        } else if selectedOutfit?.OUTERWEAR?.contains(where: { $0.id == item.id }) == true {
            return "OUTERWEAR"
        } else if selectedOutfit?.DRESS?.contains(where: { $0.id == item.id }) == true {
            return "DRESS"
        } else if selectedOutfit?.SHOES?.contains(where: { $0.id == item.id }) == true {
            return "SHOES"
        }
        return nil
    }
    
    func swapItem(newItem: ClothingItem) {
        guard let category = categoryToSwap else { return }
        guard var outfit = selectedOutfit else { return }
        
        switch category {
        case "TOP":
            if let index = outfit.TOP?.firstIndex(where: { $0.id == itemToSwap?.id }) {
                outfit.TOP?[index] = newItem
            }
        case "BOTTOM":
            if let index = outfit.BOTTOM?.firstIndex(where: { $0.id == itemToSwap?.id }) {
                outfit.BOTTOM?[index] = newItem
            }
        case "OUTERWEAR":
            if let index = outfit.OUTERWEAR?.firstIndex(where: { $0.id == itemToSwap?.id }) {
                outfit.OUTERWEAR?[index] = newItem
            }
        case "DRESS":
            if let index = outfit.DRESS?.firstIndex(where: { $0.id == itemToSwap?.id }) {
                outfit.DRESS?[index] = newItem
            }
        case "SHOES":
            if let index = outfit.SHOES?.firstIndex(where: { $0.id == itemToSwap?.id }) {
                outfit.SHOES?[index] = newItem
            }
        default:
            break
        }
        
        outfits[currentIndex] = outfit
        selectedOutfit = outfit
    }
}
