//
//  ClothingItem.swift
//  threadline
//
//  Created by Ryan Stephen on 3/21/25.
//

import Foundation

struct Clothing: Codable, Identifiable {
    let id: Int
    let type: String
    let subtype: String?
    let img_filename: String
    let color_lstar: Double
    let color_astar: Double
    let color_bstar: Double
    let fit: String
    let layerable: Bool
    let precip: String?
    let occasion: String
    let winter: Bool
    let created_at: String
    let tags: [Tag]
}

struct Tag: Codable, Identifiable {
    let label: String
    let value: String
    
    var id: String { label }
}

struct MetadataOptions {
    static let clothingTypes = ["Top", "Bottom", "Outerwear", "Dress", "Shoes"]
    static let topSubtypes = ["Active", "T-shirt", "Polo", "Button Down", "Hoodie", "Sweater"]
    static let bottomSubtypes = ["Active", "Jeans", "Pants", "Shorts", "Skirt"]
    static let outerwearSubtypes = ["Jacket", "Coat"]
    static let dressSubtypes = ["Mini", "Midi", "Maxi"]
    static let shoesSubtypes = ["Active", "Sneakers", "Boots", "Sandals & Slides"]
    static let fits = ["Loose", "Fitted", "Tight"]
    static let occasions = ["Active", "Casual", "Formal"]
    static let precipOptions = ["None", "Rain", "Snow"]
}
