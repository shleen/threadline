//
//  SwapItemView.swift
//  threadline
//
//  Created by Andy Yang on 3/22/25.
//

import SwiftUI

struct SwapItemView: View {
    let category: String
    let onItemSelected: (ClothingItem) -> Void
    
    @Environment(UrlStore.self) private var urlStore
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var items: [ClothingItem] = []
    
    var body: some View {
        VStack {
            Text("Select a new \(category)")
                .font(.headline)
                .padding()
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(items) { item in
                        Button(action: {
                            onItemSelected(item)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            AsyncImage(url: URL(string: "\(urlStore.r2BucketUrl)\(item.img)")) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                } else {
                                    Image("Sweats")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            fetchItems()
        }
    }
    
    func fetchItems() {
        // Hardcoded mock data for items
        let mockItems: [ClothingItem] = [
            ClothingItem(id: 1, img: "top1"),
            ClothingItem(id: 2, img: "top2"),
            ClothingItem(id: 3, img: "top3"),
            ClothingItem(id: 4, img: "bottom1"),
            ClothingItem(id: 5, img: "bottom2"),
            ClothingItem(id: 6, img: "bottom3"),
            ClothingItem(id: 7, img: "outerwear1"),
            ClothingItem(id: 8, img: "outerwear2"),
            ClothingItem(id: 9, img: "outerwear3"),
            ClothingItem(id: 10, img: "dress1"),
            ClothingItem(id: 11, img: "dress2"),
            ClothingItem(id: 12, img: "dress3"),
            ClothingItem(id: 13, img: "shoes1"),
            ClothingItem(id: 14, img: "shoes2"),
            ClothingItem(id: 15, img: "shoes3")
        ]
        
        switch category {
        case "TOP":
            items = mockItems.filter { $0.img.contains("top") }
        case "BOTTOM":
            items = mockItems.filter { $0.img.contains("bottom") }
        case "OUTERWEAR":
            items = mockItems.filter { $0.img.contains("outerwear") }
        case "DRESS":
            items = mockItems.filter { $0.img.contains("dress") }
        case "SHOES":
            items = mockItems.filter { $0.img.contains("shoes") }
        default:
            items = []
        }
    }
}
