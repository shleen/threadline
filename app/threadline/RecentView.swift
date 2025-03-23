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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(outfits, id: \.outfit_id) { outfit in
                    VStack(alignment: .leading) {
                        Text("Date: \(convertUTCToLocal(outfit.timestamp))")
                            .font(.headline)
                            .padding(.leading)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                outfitCategory(outfit.TOP)
                                outfitCategory(outfit.BOTTOM)
                                outfitCategory(outfit.OUTERWEAR)
                                outfitCategory(outfit.DRESS)
                                outfitCategory(outfit.SHOES)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            fetchOutfits()
        }
    }
    
    // Convert UTC timestamp to local time
    func convertUTCToLocal(_ utcString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Handles standard UTC format

        if let utcDate = formatter.date(from: utcString) {
            let localFormatter = DateFormatter()
            localFormatter.dateStyle = .medium
            localFormatter.timeStyle = .short
            localFormatter.timeZone = .current // Convert to local time

            return localFormatter.string(from: utcDate)
        }
        return "Invalid Date"
    }
    
    //function to handle each outfit category
    @ViewBuilder
    func outfitCategory(_ category: [RecentItem]?) -> some View {
        if let items = category {
            ForEach(items, id: \.clothing_id) { item in
                outfitImage(item)
            }
        }
    }
    
    // Function to load and display outfit images
    func outfitImage(_ item: RecentItem) -> some View {
        AsyncImage(url: URL(string: "\(urlStore.r2BucketUrl)\(item.img)")) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image.resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
            case .failure:
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundColor(.gray)
            @unknown default:
                EmptyView()
            }
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
                        }
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }.resume()
    }
}
