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
    let fit: String
    let layerable: Bool
    let precip: String?
    let occasion: String
    let weather: String
    let created_at: String
    let tags: [Tag]
    let colors_primary: [Int]
    let colors_secondary: [Int]
    
}
struct Tag: Codable, Identifiable {
    let label: String
    let value: String
    
    var id: String { label }
}
//TODO: Make WardrobeView and LogoutfitView use this model, and make a shared image call function for both views
