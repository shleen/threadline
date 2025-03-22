//
//  WardrobeView.swift
//  threadline
//
//  Created by James Choi on 3/6/25.
//

import SwiftUI

struct WardrobeView: View {
    @AppStorage("username") private var username: String = ""
    @Environment(UrlStore.self) private var urlStore
    
    @State private var clothingItems: [Clothing] = []
    
    //Todo get images from backend using database
    //let images = ["image1", "image2", "image3", "image4", "image5", "image6"]
    let images = ["Example", "Sweats", "Example", "Example", "Example"]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(clothingItems) { item in
                        // Construct full URL by combining R2 bucket URL with image filename
                        AsyncImage(url: URL(string: "\(urlStore.r2BucketUrl)\(item.img_filename)")) { image in
                            image
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipped()
                                .cornerRadius(10)
                        } placeholder: {
                            ProgressView()
                                .frame(width: 100, height: 100)
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            fetchCloset()
        }
    }
    
    func fetchCloset() {
        guard let url = URL(string: "\(urlStore.serverUrl)/closet/get?username=\(username)") else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching closet: \(error)")
                return
            }
            
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode([String: [Clothing]].self, from: data)
                    if let items = decodedResponse["items"] {
                        DispatchQueue.main.async {
                            // Sort by newest first
                            self.clothingItems = items.sorted { $0.created_at > $1.created_at }
                        }
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw response: \(responseString)")
                    }
                }
            }
        }.resume()
    }
}
