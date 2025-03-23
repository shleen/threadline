//
//  SwapItemView.swift
//  threadline
//
//  Created by Andy Yang on 3/22/25.
//

import Foundation

struct ClothingItem: Codable, Identifiable, Equatable {
    let id: Int
    let img: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case img = "img_filename"
        case imgAlt = "img"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        if let img = try? container.decode(String.self, forKey: .img) {
            self.img = img
        } else {
            self.img = try container.decode(String.self, forKey: .imgAlt)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(img, forKey: .imgAlt)
    }
}

struct Outfit: Codable {
    var TOP: [ClothingItem]?
    var BOTTOM: [ClothingItem]?
    var OUTERWEAR: [ClothingItem]?
    var DRESS: [ClothingItem]?
    var SHOES: [ClothingItem]?
}

struct ClosetResponse: Codable {
    let items: [ClothingItem]
}
