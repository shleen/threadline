//
//  GenerateView.swift
//  threadline
//
//  Created by James Choi on 3/15/25.
//

import SwiftUI

struct Outfit: Codable {
    let TOP: [ClothingItem]?
    let BOTTOM: [ClothingItem]?
    let OUTERWEAR: [ClothingItem]?
    let DRESS: [ClothingItem]?
    let SHOES: [ClothingItem]?
}

struct ClothingItem: Codable {
    let id: Int
    let img: String
}

struct GenerateView: View {
    @AppStorage("username") private var username: String = ""
    
    @Environment(UrlStore.self) private var urlStore
    
    @ObservedObject private var locationManager = LocationManager.shared

    @State private var outfits: [Outfit] = []
    @State private var selectedOutfit: Outfit?
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
                
                Button(action: {
                    nextOutfit()
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding(8)
                        .background(Color.white.opacity(0.7))
                        .clipShape(Circle())
                }
                .offset(x: 80, y: 80)
            }
                
            Spacer()
            
            Button(action: {
                print("Wear this outfit tapped")
            }) {
                Text("Wear this outfit")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .onAppear {
            fetchOutfits()
        }
    }
    
    func fetchOutfits() {
        locationManager.requestLocation { location in
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude

            guard let url = URL(string: "\(urlStore.serverUrl)/recommendation/get?username=\(username)&lat=\(lat)&lon=\(lon)") else { return }

            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        let decodedResponse = try JSONDecoder().decode([String: [Outfit]].self, from: data)
                        if let fetchedOutfits = decodedResponse["outfits"], !fetchedOutfits.isEmpty {
                            DispatchQueue.main.async {
                                self.outfits = fetchedOutfits
                                self.selectedOutfit = fetchedOutfits.first
                                self.currentIndex = 0
                            }
                        }
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                }
            }.resume()
        }
    }
    
    func nextOutfit() {
        guard !outfits.isEmpty else { return }
        currentIndex = (currentIndex + 1) % outfits.count
        selectedOutfit = outfits[currentIndex]
    }
}
