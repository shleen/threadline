//
//  TagView.swift
//  threadline
//
//  Created by Andy Yang on 3/10/25.
//

import SwiftUI

struct TagView: View {
    @AppStorage("username") private var username: String = ""

    @Environment(UrlStore.self) private var urlStore
    @Environment(\.dismiss) private var dismiss

    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var selectedCategory: String? = nil
    @State private var showSuccessSnackbar = false
    @State private var navigateToWardrobe = false

    @State private var image: UIImage?
    @State private var isImagePickerPresented = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingOptions = false

    let categories = ["TOP", "BOTTOM", "OUTERWEAR", "DRESS", "SHOES"]

    var body: some View {
        VStack {
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
                        Text("Upload an image")
                            .foregroundColor(.gray)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }.padding()

            HStack {
                TextField("Enter tag", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button(action: {
                    if !newTag.isEmpty {
                        tags.append(newTag)
                        newTag = ""
                    }
                }) {
                    Text("Add Tag")
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            
            Picker("Select Category", selection: $selectedCategory) {
                Text("Select Category").tag(String?.none)
                ForEach(categories, id: \.self) { category in
                    Text(category).tag(String?.some(category))
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            ScrollView(.horizontal) {
                HStack {
                    ForEach(tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(16)
                            Button(action: {
                                if let index = tags.firstIndex(of: tag) {
                                    tags.remove(at: index)
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding()
            }

            Spacer()

            Button(action: {
                // Handle done action
                createClothingItem()
            }) {
                Text("Done")
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(selectedCategory == nil || image == nil ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            .disabled(selectedCategory == nil || image == nil)
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePickerCoordinator(image: $image, sourceType: sourceType) { selectedImage in
                // After an image is selected, remove the background
                removeBackground(from: selectedImage)
            }
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
            Text("Upload an image of a clothing item to get started.")
        }
        .onAppear {
            // Show options dialog when view appears
            showingOptions = true
        }
        .overlay(alignment: .bottom) {
            if showSuccessSnackbar {
                Text("\(selectedCategory ?? "Item") created successfully!")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.bottom)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut, value: showSuccessSnackbar)
        .navigationDestination(isPresented: $navigateToWardrobe) {
            WardrobeView()
        }
    }

    func createClothingItem() {
        var multipart = MultipartRequest()

        // Create form body
        multipart.add(key: "username", value: username)
        multipart.add(key: "type", value: selectedCategory?.uppercased() ?? "")
        multipart.add(key: "tags", value: tags)
        multipart.add(
            key: "image",
            fileName: "image.jpg",
            fileMimeType: "image/jpeg",
            fileData: image!.jpegData(compressionQuality: 0.8)!
        )

        /// Create a regular HTTP URL request & use multipart components
        guard let url = URL(string: "\(urlStore.serverUrl)/clothing/create") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(multipart.httpContentTypeHeadeValue, forHTTPHeaderField: "Content-Type")
        request.httpBody = multipart.httpBody

        // Make network request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else { return }
            print("Response status code: \(httpResponse.statusCode)")

            DispatchQueue.main.async {
                if httpResponse.statusCode == 200 {
                    showSuccessSnackbar = true
                    // Wait for snackbar animation before navigating
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        navigateToWardrobe = true
                    }
                }
            }
        }.resume()
    }

    func removeBackground(from image: UIImage) {
        var multipart = MultipartRequest()
        multipart.add(key: "username", value: username)
        multipart.add(
            key: "image",
            fileName: "image.png",
            fileMimeType: "image/png",
            fileData: image.pngData()!
        )

        guard let url = URL(string: "\(urlStore.serverUrl)/background/remove") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(multipart.httpContentTypeHeadeValue, forHTTPHeaderField: "Content-Type")
        request.httpBody = multipart.httpBody

        // Process in background without blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Background removal error: \(error)")
                    return
                }

                guard let data = data,
                      let processedImage = UIImage(data: data) else { return }

                DispatchQueue.main.async {
                    self.image = processedImage
                }
            }.resume()
        }
    }
}

struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        TagView()
    }
}

struct ImagePickerCoordinator: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) var presentationMode
    var onImageSelected: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerCoordinator

        init(_ parent: ImagePickerCoordinator) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image  // Show original image immediately
                parent.onImageSelected(image)  // Process background removal in background
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
