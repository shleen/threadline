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
    @State private var image: UIImage?
    @State private var isImagePickerPresented = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingOptions = false

    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: 3)
    @State private var selectedItems: Set<Int> = []

    private let closetGetRoute = "/closet/get"
    private let outfitPostRoute = "/outfit/post"

    func saveOutfit() {
        guard let apiUrl = URL(string: "\(urlStore.serverUrl)\(outfitPostRoute)") else {
            print("log_outfit: Bad URL")
            return
        }

        var multipart = MultipartRequest()
        multipart.add(key: "username", value: username)
        multipart.add(key: "clothing_ids", value: Array(selectedItems).map { String($0) }.joined(separator: ","))

        if let imageData = image?.jpegData(compressionQuality: 0.8) {
            multipart.add(
                key: "image",
                fileName: "image.jpg",
                fileMimeType: "image/jpeg",
                fileData: imageData
            )
        }

        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue(multipart.httpContentTypeHeadeValue, forHTTPHeaderField: "Content-Type")
        request.httpBody = multipart.httpBody

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

                Button(action: {
                    showingOptions = true
                }) {
                    if let displayImage = image {
                        Image(uiImage: displayImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .padding()
                    } else {
                        VStack {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                            Text("Upload an OOTD photo!")
                                .foregroundColor(.gray)
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()

                ScrollView {
                    LazyVGrid(columns: gridColumns) {
                        ForEach(items) { item in
                            LogOutfitItemView(selectedItems: $selectedItems, item: item)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePickerCoordinator(image: $image, sourceType: sourceType) { _ in }
            }
            .confirmationDialog("Select Image", isPresented: $showingOptions) {
                Button("Take Photo") {
                    sourceType = .camera
                    isImagePickerPresented = true
                }
                Button("Choose from Library") {
                    sourceType = .photoLibrary
                    isImagePickerPresented = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Upload a photo of your outfit.")
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
