//
//  GenerateView.swift
//  threadline
//
//  Created by James Choi on 3/15/25.
//

import SwiftUI

struct Outfit: Codable {
    var TOP: [ClothingItem]?
    var BOTTOM: [ClothingItem]?
    var OUTERWEAR: [ClothingItem]?
    var DRESS: [ClothingItem]?
    var SHOES: [ClothingItem]?
}

struct ClothingItem: Codable, Identifiable, Equatable {
    let id: Int
    let img: String
}

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
        // Hardcoded mock data for 5 outfits
        let mockOutfits: [Outfit] = [
            Outfit(TOP: [ClothingItem(id: 1, img: "top1")], BOTTOM: [ClothingItem(id: 2, img: "bottom1")], OUTERWEAR: [ClothingItem(id: 3, img: "outerwear1")], DRESS: nil, SHOES: [ClothingItem(id: 4, img: "shoes1")]),
            Outfit(TOP: [ClothingItem(id: 5, img: "top2")], BOTTOM: [ClothingItem(id: 6, img: "bottom2")], OUTERWEAR: nil, DRESS: nil, SHOES: [ClothingItem(id: 7, img: "shoes2")]),
            Outfit(TOP: [ClothingItem(id: 8, img: "top3")], BOTTOM: [ClothingItem(id: 9, img: "bottom3")], OUTERWEAR: [ClothingItem(id: 10, img: "outerwear2")], DRESS: nil, SHOES: [ClothingItem(id: 11, img: "shoes3")]),
            Outfit(TOP: [ClothingItem(id: 12, img: "top4")], BOTTOM: [ClothingItem(id: 13, img: "bottom4")], OUTERWEAR: nil, DRESS: [ClothingItem(id: 14, img: "dress1")], SHOES: [ClothingItem(id: 15, img: "shoes4")]),
            Outfit(TOP: [ClothingItem(id: 16, img: "top5")], BOTTOM: [ClothingItem(id: 17, img: "bottom5")], OUTERWEAR: [ClothingItem(id: 18, img: "outerwear3")], DRESS: [ClothingItem(id: 19, img: "shoes5")], SHOES: [ClothingItem(id: 20, img: "shoes5")])
        ]
        
        DispatchQueue.main.async {
            self.outfits = mockOutfits
            self.selectedOutfit = mockOutfits.first
            self.currentIndex = 0
            printOutfits(outfits: mockOutfits) // Print the contents of the outfits array
        }
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
