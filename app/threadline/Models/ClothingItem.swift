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
