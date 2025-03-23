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
    
    @AppStorage("username") private var username: String = ""
    
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
        guard let url = URL(string: "\(urlStore.serverUrl)/closet/get?username=\(username)&type=\(category)") else {
            print("Invalid URL")
            return
        }
        print(url)
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(ClosetResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.items = decodedResponse.items
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            } else if let error = error {
                print("Error fetching items: \(error)")
            }
        }.resume()
    }
}
