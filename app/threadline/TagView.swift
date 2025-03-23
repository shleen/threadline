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

    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var selectedCategory: String? = nil
    @State private var showSuccessSnackbar = false
    @State private var navigateToWardrobe = false
    @State private var selectedSubtype: String? = nil
    @State private var selectedFit: String? = nil
    @State private var selectedOccasion: String? = nil
    @State private var selectedPrecip: String? = nil
    @State private var isWinter: String? = nil
    @State private var image: UIImage?
    @State private var isImagePickerPresented = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingOptions = false

    let categories = ["TOP", "BOTTOM", "OUTERWEAR", "DRESS", "SHOES"]
    let topSubtypes = ["ACTIVE", "T-SHIRT", "POLO", "BUTTON DOWN", "HOODIE", "SWEATER"]
    let bottomSubtypes = ["ACTIVE", "JEANS", "PANTS", "SHORTS", "SKIRT"]
    let outerwearSubtypes = ["JACKET", "COAT"]
    let dressSubtypes = ["MINI", "MIDI", "MAXI"]
    let shoesSubtypes = ["ACTIVE", "SNEAKERS", "BOOTS", "SANDALS & SLIDES"]
    let fits = ["LOOSE", "FITTED", "TIGHT"]
    let occasions = ["ACTIVE", "CASUAL", "FORMAL"]
    let precips = ["RAIN", "SNOW"]
    let winterOptions = ["Winter", "Not Winter"]

    var body: some View {
        ScrollView {
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

                if let selectedCategory = selectedCategory {
                    Picker("Select Subtype", selection: $selectedSubtype) {
                        Text("Select Subtype").tag(String?.none)
                        ForEach(getSubtypes(for: selectedCategory), id: \.self) { subtype in
                            Text(subtype).tag(String?.some(subtype))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    
                    Picker("Select Fit", selection: $selectedFit) {
                        Text("Select Fit").tag(String?.none)
                        ForEach(fits, id: \.self) { fit in
                            Text(fit).tag(String?.some(fit))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    
                    Picker("Select Occasion", selection: $selectedOccasion) {
                        Text("Select Occasion").tag(String?.none)
                        ForEach(occasions, id: \.self) { occasion in
                            Text(occasion).tag(String?.some(occasion))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()

                    Picker("Select Precipitation", selection: $selectedPrecip) {
                        Text("Select Precipitation").tag(String?.none)
                        ForEach(precips, id: \.self) { precip in
                            Text(precip).tag(String?.some(precip))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    
                    Picker("Winter", selection: $isWinter) {
                        Text("Select Winter Option").tag(String?.none)
                        ForEach(winterOptions, id: \.self) { option in
                            Text(option).tag(option == "Winter" ? "True" : "False")
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                }

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
                        .background(isFormValid() ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .disabled(!isFormValid())
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePickerCoordinator(image: $image, sourceType: sourceType)
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
    }

    func getSubtypes(for category: String) -> [String] {
        switch category {
        case "TOP":
            return topSubtypes
        case "BOTTOM":
            return bottomSubtypes
        case "OUTERWEAR":
            return outerwearSubtypes
        case "DRESS":
            return dressSubtypes
        case "SHOES":
            return shoesSubtypes
        default:
            return []
        }
    }

    func isFormValid() -> Bool {
        return selectedCategory != nil &&
               selectedSubtype != nil &&
               selectedFit != nil &&
               selectedOccasion != nil &&
               isWinter != nil &&
               image != nil
    }

    func createClothingItem() {
        var multipart = MultipartRequest()

        // Create form body
        multipart.add(key: "username", value: username)
        multipart.add(key: "type", value: selectedCategory?.uppercased() ?? "")
        multipart.add(key: "tags", value: tags.joined(separator: ","))
        multipart.add(key: "subtype", value: selectedSubtype ?? "")
        multipart.add(key: "fit", value: selectedFit ?? "")
        multipart.add(key: "occasion", value: selectedOccasion ?? "")
        multipart.add(key: "isWinter", value: isWinter ?? "")

        if let selectedPrecip = selectedPrecip {
            multipart.add(key: "precipitation", value: selectedPrecip)
        }

        if let imageData = image?.jpegData(compressionQuality: 0.8) {
            multipart.add(
                key: "image",
                fileName: "image.jpg",
                fileMimeType: "image/jpeg",
                fileData: imageData
            )
        }

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
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}