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
    @State private var selectedItem: Clothing? = nil
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.992, blue: 0.91).edgesIgnoringSafeArea(.all)
            VStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(clothingItems) { item in
                            // Construct full URL by combining R2 bucket URL with image filename
                            AsyncImage(url: URL(string: "\(urlStore.r2BucketUrl)\(item.img_filename)")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                                    .frame(width: 115, height: 115)
                                    .clipped()
                                    .cornerRadius(10)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(color: Color.gray.opacity(0.55), radius: 20, x: 0, y: 5)
                                    .padding(.top, 15)
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            }
                            .onTapGesture {
                                selectedItem = item
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(Text("Wardrobe"))
        }
        .sheet(item: $selectedItem) { item in
            ClothingDetailView(item: item, clothingItems: $clothingItems)
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

struct ClothingDetailView: View {
    let item: Clothing
    @Binding var clothingItems: [Clothing]
    @Environment(UrlStore.self) private var urlStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image
                    AsyncImage(url: URL(string: "\(urlStore.r2BucketUrl)\(item.img_filename)")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow("Type", item.type.capitalized)
                        if let subtype = item.subtype {
                            detailRow("Subtype", subtype.capitalized)
                        }
                        detailRow("Fit", item.fit.capitalized)
                        detailRow("Occasion", item.occasion.capitalized)
                        
                        
                        if !item.tags.isEmpty {
                            Text("Tags")
                                .fontWeight(.medium)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(item.tags) { tag in
                                        Text(tag.value)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        // Remove from UI
                        clothingItems.removeAll(where: { [item.id].contains($0.id) })
                        
                        // POST to declutter endpoint
                        Task {
                            await postDeclutter([item.id], urlStore.serverUrl)
                        }
                        
                        // Dismiss pop up
                        dismiss()
                    }) {
                        Image(systemName: "trash")
                            .imageScale(.large)
                            .foregroundStyle(.red)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}
