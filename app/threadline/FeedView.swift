////
////  HomeView.swift
////  threadline
////
////  Created by sheline on 4/12/25.
////

import SwiftUI

struct FeedItem: Codable, Identifiable {
    let id: Int
    let img_filename: String
    let date_worn: String
    let username: String
    let clothing_items: [Clothing]
}

struct FeedResponse: Codable {
    let outfits: [FeedItem]
    let next_cursor: String?
}

struct FeedView: View {
    @AppStorage("username") private var username: String = ""
    @Environment(UrlStore.self) private var urlStore
    
    @State private var outfits: [FeedItem] = []
    @State private var nextCursor: String?
    @State private var isLoading = false
    @State private var hasMore = true
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Activity")
                .font(.system(size: 18, weight: .medium)) 
                .padding(.top, 20)
                .padding(.bottom, 2)

            Text("See what other users have been wearing recently.")
                .font(.system(size: 14, weight: .light))
                .padding(.bottom, 4)
            
            LazyVStack(spacing: 20) {
                ForEach(outfits) { outfit in
                    FeedItemView(outfit: outfit)
                        .onAppear {
                            if outfit.id == outfits.last?.id {
                                loadMoreOutfits()
                            }
                        }
                }
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
        .padding(.horizontal, 16)
        .onAppear {
            if outfits.isEmpty {
                loadInitialOutfits()
            }
        }
    }
    
    private func loadInitialOutfits() {
        guard let url = URL(string: "\(urlStore.serverUrl)/feed/get?page_size=10") else { return }
        
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { isLoading = false }
            
            if let data = data {
                do {
                    let response = try JSONDecoder().decode(FeedResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.outfits = response.outfits
                        self.nextCursor = response.next_cursor
                        self.hasMore = response.next_cursor != nil
                    }
                } catch {
                    print("Error decoding feed response: \(error)")
                }
            }
        }.resume()
    }
    
    private func loadMoreOutfits() {
        guard !isLoading, hasMore, let cursor = nextCursor,
              let url = URL(string: "\(urlStore.serverUrl)/feed/get?cursor=\(cursor)&page_size=10") else { return }
        
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { isLoading = false }
            
            if let data = data {
                do {
                    let response = try JSONDecoder().decode(FeedResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.outfits.append(contentsOf: response.outfits)
                        self.nextCursor = response.next_cursor
                        self.hasMore = response.next_cursor != nil
                    }
                } catch {
                    print("Error decoding feed response: \(error)")
                }
            }
        }.resume()
    }
}

struct FeedItemView: View {
    let outfit: FeedItem

    @AppStorage("username") private var username: String = ""
    @Environment(UrlStore.self) private var urlStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with username and date
            HStack {
                HStack(spacing: 4) {
                    Text(outfit.username)
                        .font(.headline)
                    if outfit.username == username {
                        Text("(You)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                Spacer()
                Text(formatDate(outfit.date_worn))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Outfit image
            AsyncImage(url: URL(string: "\(urlStore.r2BucketUrl)\(outfit.img_filename)")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 300)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            
            // Clothing items grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(outfit.clothing_items) { item in
                        AsyncImage(url: URL(string: "\(urlStore.r2BucketUrl)\(item.img_filename)")) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 80, height: 80)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.gray.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let localFormatter = DateFormatter()
            localFormatter.dateStyle = .medium
            localFormatter.timeStyle = .short
            localFormatter.timeZone = .current
            
            return localFormatter.string(from: date)
        }
        return "Invalid Date"
    }
}
