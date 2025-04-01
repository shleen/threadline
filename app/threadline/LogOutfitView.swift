//
//  LogOutfitView.swift
//  threadline
//
//  Created by sheline on 1/27/25.
//

import SwiftUI

// TODO: Update after integrating with backend
struct LogOutfitItem: Identifiable {
    let id: Int
    let img_filename: String
}

struct LogOutfitView: View {
    @AppStorage("username") private var username: String = ""

    @Binding var isPresented: Bool

    @Environment(UrlStore.self) private var urlStore

    @State var items: Array<LogOutfitItem>

    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: 3)
    @State private var selectedItems: Set<Int> = []

    private let closetGetRoute = "/closet/get"
    private let outfitPostRoute = "/outfit/post"

    func saveOutfit() {
        guard let apiUrl = URL(string: "\(urlStore.serverUrl)\(outfitPostRoute)") else {
            print("log_outfit: Bad URL")
            return
        }

        let payload: [String: Any] = [
            "username": username,
            "clothing_ids": Array(selectedItems)
        ]

        var request = URLRequest(url: apiUrl)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        Task(priority: .background) {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("\(outfitPostRoute): HTTP STATUS: \(httpStatus.statusCode)")
                return
            }

            isPresented.toggle()
        }
    }

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.992, blue: 0.91).edgesIgnoringSafeArea(.all)
            VStack(spacing: 4) {
                Text("What are you wearing today?")
                    .font(.headline)
                    .padding(.bottom, 16)
                ScrollView {
                    LazyVGrid(columns: gridColumns) {
                        ForEach(items) { item in
                            LogOutfitItemView(selectedItems: $selectedItems, item: item)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .toolbar {
                Button(action: saveOutfit) {
                    Text("Done")
                }
                .disabled(selectedItems.isEmpty)
            }
            .onAppear {
                // Call backend to populate clothing
                guard let apiUrl = URL(string: "\(urlStore.serverUrl)\(closetGetRoute)?username=\(username)") else {
                    print("\(closetGetRoute): Bad URL")
                    return
                }
                
                var request = URLRequest(url: apiUrl)
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept") // expect response in JSON
                request.httpMethod = "GET"
                
                Task(priority: .background) {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                        print("\(closetGetRoute): HTTP STATUS: \(httpStatus.statusCode)")
                        return
                    }
                    
                    guard let clothingReceived = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        print("\(closetGetRoute): failed JSON deserialization")
                        return
                    }
                    
                    for c in clothingReceived["items"] as! [[String: Any]] {
                        if let id  = c["id"] as? Int, let img_filename = c["img_filename"] as? String {
                            items.append(
                                LogOutfitItem(id: id, img_filename: img_filename)
                            )
                        }
                    }
                }
            }
        }
    }
}
