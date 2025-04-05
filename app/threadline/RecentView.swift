//
//  RecentView.swift
//  threadline
//
//  Created by James Choi on 3/21/25.
//

import SwiftUI

struct RecentOutfit: Codable {
    let outfit_id: Int
    let timestamp: String
    let clothes: [RecentItem]?
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
        NavigationView {
            ZStack {
                Color(red: 1.0, green: 0.992, blue: 0.91).edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(outfits, id: \.outfit_id) { outfit in
                            VStack(alignment: .leading) {
                                Text("\(convertUTCToLocal(outfit.timestamp))")
                                    .font(.headline)
                                    .padding([.leading, .top], 16)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 5) {
                                        outfitCategory(outfit.clothes)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Color.gray.opacity(0.65), radius: 20, x: 0, y: 5)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    fetchOutfits()
                }
            }
           .navigationBarTitle(Text("Previous Outfits"))
        }
    }
    
    // Convert UTC timestamp to local time
    func convertUTCToLocal(_ utcString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Handles standard UTC format

        if let utcDate = formatter.date(from: utcString) {
            let localFormatter = DateFormatter()
            localFormatter.dateStyle = .medium
//            localFormatter.timeStyle = .short
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
                    .frame(width: 110, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
//                    .shadow(radius: 5)
                    .padding(.bottom, 30)
                    .padding(.top, 10)
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
