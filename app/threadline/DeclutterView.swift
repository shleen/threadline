//
//  DeclutterView.swift
//  threadline
//
//  Created by Stephen Barstys on 4/5/25.
//

import SwiftUI

struct DeclutterItem: Codable {
    let id: Int
    let img_filename: String
    let wear_counts: Int
    let recent: String?
}

struct DeclutterResponse: Codable {
    var declutter: [DeclutterItem]
}

struct DeclutterView: View {
    @AppStorage("username") private var username: String = ""
    @Environment(UrlStore.self) private var urlStore
    @State private var declutter: DeclutterResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 1.0, green: 0.992, blue: 0.91).edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Least Worn Items")
                                .font(.headline)
                                .padding(.top, 15)
                                .padding(.leading, 15)
                            
                            VStack {
                                if let declutter = declutter {
                                    if declutter.declutter.isEmpty {
                                        Text("No items to declutter at this time")
                                            .foregroundColor(.secondary)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal)
                                            .background(Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                            .shadow(color: Color.gray.opacity(0.85), radius: 20, x: 0, y: 5)
                                    }
                                    else {
                                        ForEach(declutter.declutter, id: \.id) { decl in
                                            HStack(spacing: 12) {
                                                AsyncImage(url: URL(string: "\(urlStore.r2BucketUrl)\(decl.img_filename)")) { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                } placeholder: {
                                                    Color.gray
                                                }
                                                .frame(width: 120, height: 120)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .padding(.top, 8)
                                                
                                                VStack {
                                                    Text(wearCountText(decl.wear_counts))
                                                    if let timestamp = decl.recent {
                                                        Text("\(convertUTCToLocal(timestamp))")
                                                            .foregroundStyle(.blue)
                                                    }
                                                }
                                                .padding(.leading, 15)
                                                .padding(.trailing, 35)
                                                
                                                
                                                Button(action: {
                                                    Task { await deleteGarm([decl.id]) }
                                                }) {
                                                    Image(systemName: "trash")
                                                        .imageScale(.large)
                                                        .foregroundStyle(.red)
                                                }
                                            }
                                        }
                                        Button(action: {
                                            Task { await deleteGarm(declutter.declutter.map {$0.id}) }
                                        }) {
                                            Text("Remove All")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .background(Color.red)
                                                .cornerRadius(10)
                                                .padding(.horizontal, 10)
                                                .padding(.bottom, 15)
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                            }
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Color.gray.opacity(0.85), radius: 20, x: 0, y:5)
                            .padding(.top, 4)
                            .padding([.leading, .trailing], 15)
                        }
                    }
                }
            }
            .navigationTitle(Text("Declutter"))
        }
        .onAppear {
            Task {
                await fetchDeclutter()
            }
        }
    }
    
    private func deleteGarm(_ ids: [Int]) async {
        // Remove the rows from the UI
        declutter?.declutter.removeAll(where: { ids.contains($0.id) })
        
        // POST to backend for a soft delete
        await postDeclutter(ids, urlStore.serverUrl)
        
        // If the UI has been cleared refresh it with new recommendations
        if let decl = declutter {
            if decl.declutter.isEmpty {
                Task {
                    await fetchDeclutter()
                }
            }
        }
    }
    
    private func wearCountText(_ wear_counts: Int) -> String {
        var text = ""
        switch wear_counts {
            case 0: text = "Never worn"
            case 1: text = "Worn once"
            default: text = "Worn \(wear_counts) times"
        }
        return text
    }
    
    private func fetchDeclutter() async {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(urlStore.serverUrl)/declutter/get?username=\(username)") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            guard httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let decoder = JSONDecoder()
            self.declutter = try decoder.decode(DeclutterResponse.self, from: data)
            
        } catch {
            errorMessage = "Failed to load declutter items: \(error)"
        }
        isLoading = false
    }
}

func postDeclutter(_ ids: [Int], _ serverUrl: String) async {
    guard let url = URL(string: "\(serverUrl)/declutter/post") else {
        print("Invalid URL")
        return
    }
    
    let payload: [String: Any] = [
        "ids": ids
    ]
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
    } catch {
        print("Error serializing JSON: \(error)")
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error deleting garment: \(error)")
            return
        }
        if let response = response as? HTTPURLResponse, response.statusCode == 200 {
            print("Garment removed successfully")
        } else {
            print("Failed to remove garment")
        }
    }.resume()
}

#Preview {
    DeclutterView()
}
