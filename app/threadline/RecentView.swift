//
//  RecentView.swift
//  threadline
//
//  Created by James Choi on 3/21/25.
//

import SwiftUI

struct RecentOutfit: Codable {
    let TOP: [RecentItem]?
    let BOTTOM: [RecentItem]?
    let OUTERWEAR: [RecentItem]?
    let DRESS: [RecentItem]?
    let SHOES: [RecentItem]?
    let outfit_id: Int
    let timestamp: String
}

struct RecentItem: Codable {
    let clothing_id: Int
    let img: String
}

struct RecentView: View {
    @AppStorage("username") private var username: String = ""
    
    @Environment(UrlStore.self) private var urlStore

    @State private var outfits: [RecentOutfit] = []
    @State private var selectedOutfit: RecentOutfit?
    @State private var currentIndex: Int = 0
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                Image("outfit") // Replace "outfit" with your actual image name
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            
            Spacer()
        }
        .onAppear {
            fetchOutfits()
        }
    }
    
    func fetchOutfits() {
        guard let url = URL(string: "\(urlStore.serverUrl)/outfits/get?username=\(username)") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode([String: [RecentOutfit]].self, from: data)
                    if let fetchedOutfits = decodedResponse["outfits"], !fetchedOutfits.isEmpty {
                        DispatchQueue.main.async {
                            self.outfits = fetchedOutfits
                            self.selectedOutfit = self.outfits.first
                            self.currentIndex = 0
                        }
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }.resume()
    }
    
    func nextOutfit() {
        guard !outfits.isEmpty else { return }
        currentIndex = (currentIndex + 1) % outfits.count
        selectedOutfit = outfits[currentIndex]
    }
}
