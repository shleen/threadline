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
    let wears: Int
    let last_wear: String
}

struct DeclutterResonse: Codable {
    let declutter: [DeclutterItem]
}

struct DeclutterView: View {
    @AppStorage("username") private var username: String = ""
    @Environment(UrlStore.self) private var urlStore
    @State private var declutter: [DeclutterItem] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 1.0, green: 0.992, blue: 0.91).edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if declutter.isEmpty {
                            Text("No items to declutter at this time")
                        }
                        else {
                            Button(action: {
                            }) {
                                Text("Remove All")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red)
                                    .cornerRadius(10)
                                    .padding(.horizontal, 10)
                            }
                            .padding(.top, 10)
                        }
                        
                    }
                    .padding(.bottom, 15)
                    .padding(.top, 20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.gray.opacity(0.18), radius: 20, x: 0, y:5)
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
    
    private func fetchDeclutter() async {
        
    }
}

#Preview {
    DeclutterView()
}
