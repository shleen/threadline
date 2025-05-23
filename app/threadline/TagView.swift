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
    
    @FocusState private var keyboard: Bool

    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var selectedCategory: String? = nil
    @State private var showSuccessSnackbar = false
    @State private var navigateToWardrobe = false
    @State private var selectedSubtype: String? = nil
    @State private var selectedFit: String? = nil
    @State private var selectedOccasion: String? = nil
    @State private var selectedPrecip: String? = nil
    @State private var selectedWeather: String? = nil
    @State private var image: UIImage?
    @State private var isImagePickerPresented = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingOptions = false
    @State private var primaryColor: RGBColor = RGBColor(red: 128, green: 128, blue: 128)
    @State private var secondaryColor: RGBColor = RGBColor(red: 128, green: 128, blue: 128)
    @State private var isLoading = false
    @State private var isProcessingImage = false

    // Dynamic data fetched from the server
    @State private var categories: [String] = []
    @State private var subtypes: [String: [String]] = [:] // Dictionary to store subtypes dynamically
    @State private var fits: [String] = []
    @State private var occasions: [String] = []
    @State private var precips: [String] = []
    @State private var weatherOptions: [String] = []

    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)
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
                                .overlay(alignment: .bottom) {
                                    if isProcessingImage {
                                        HStack {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            Text("Removing background...")
                                                .foregroundColor(.white)
                                        }
                                        .padding(4)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.black.opacity(0.5))
                                        .cornerRadius(8)
                                    }
                                }
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
                    
                    HStack(spacing: 20) {
                        HStack {
                            Rectangle()
                                .fill(primaryColor.color)
                                .frame(width: 30, height: 30)
                                .cornerRadius(4)
                            Text("Primary")
                                .font(.caption)
                        }

                        HStack {
                            Rectangle()
                                .fill(secondaryColor.color)
                                .frame(width: 30, height: 30)
                                .cornerRadius(4)
                            Text("Secondary")
                                .font(.caption)
                        }
                    }
                    .padding(.bottom, 10)
                    
                    HStack {
                        TextField("Enter tag", text: $newTag)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .focused($keyboard)
                        
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
                        
                        Picker("Select Weather", selection: $selectedWeather) {
                            Text("Select Weather").tag(String?.none)
                            ForEach(weatherOptions, id: \.self) { option in
                                Text(option).tag(String?.some(option))
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
                        isLoading = true
                        createClothingItem()
                    }) {
                        if isLoading {
                            ProgressView()
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .background(Color.gray)
                                .cornerRadius(8)
                        }
                        else {
                            Text("Done")
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .background(isFormValid() ? Color.green : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .disabled(!isFormValid() || isLoading)
                }
                .onAppear {
                    fetchCategories()
                }
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePickerCoordinator(image: $image, sourceType: sourceType) { selectedImage in
                        self.image = selectedImage
                        processImageForColors(selectedImage)
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
            .onTapGesture {
                keyboard.toggle()
            }
        }
    }

    func fetchCategories() {
        guard let url = URL(string: "\(urlStore.serverUrl)/categories/get") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching categories: \(error)")
                return
            }
            
            guard let data = data else { return }
            // Debug: Print raw response data
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw response category: \(rawResponse)")
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    DispatchQueue.main.async {
                        self.categories = json["type"] as? [String] ?? []
                        self.fits = json["fit"] as? [String] ?? []
                        self.occasions = json["occasion"] as? [String] ?? []
                        self.precips = json["precip"] as? [String] ?? []
                        self.weatherOptions = json["weather"] as? [String] ?? []
                        
                        if let subtypeArray = json["subtype"] as? [[String: Any]] {
                            for subtype in subtypeArray {
                                if let type = subtype["type"] as? String,
                                    let subtypes = subtype["subtypes"] as? [String] {
                                    self.subtypes[type] = subtypes
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Error decoding categories JSON: \(error)")
            }
        }.resume()
    }

    func getSubtypes(for category: String) -> [String] {
        return subtypes[category] ?? []
    }

    func isFormValid() -> Bool {
        return selectedCategory != nil &&
               selectedSubtype != nil &&
               selectedFit != nil &&
               selectedOccasion != nil &&
               selectedWeather != nil &&
               image != nil &&
               !isProcessingImage
    }

    func extractRGB(from color: RGBColor) -> [Int] {
        return [color.red, color.green, color.blue]
    }

    func createClothingItem() {
        var multipart = MultipartRequest()

        // Add required fields
        multipart.add(key: "username", value: username)
        multipart.add(key: "type", value: selectedCategory?.uppercased() ?? "")
        multipart.add(key: "fit", value: selectedFit ?? "")
        multipart.add(key: "occasion", value: selectedOccasion ?? "")
        multipart.add(key: "winter", value: selectedWeather == "WINTER" ? "True" : "False")

        // Extract primary and secondary colors as RGB arrays
        let primaryRGB = extractRGB(from: primaryColor)
        let secondaryRGB = extractRGB(from: secondaryColor)

        // Add primary and secondary colors
        multipart.add(key: "red", value: "\(primaryRGB[0])")
        multipart.add(key: "green", value: "\(primaryRGB[1])")
        multipart.add(key: "blue", value: "\(primaryRGB[2])")
        multipart.add(key: "red_secondary", value: "\(secondaryRGB[0])")
        multipart.add(key: "green_secondary", value: "\(secondaryRGB[1])")
        multipart.add(key: "blue_secondary", value: "\(secondaryRGB[2])")

        // Add optional fields
        if let selectedSubtype = selectedSubtype {
            multipart.add(key: "subtype", value: selectedSubtype)
        }
        if let selectedPrecip = selectedPrecip {
            multipart.add(key: "precip", value: selectedPrecip)
        }
        if !tags.isEmpty {
            multipart.add(key: "tags", value: tags.joined(separator: ","))
        }

        // Add image
        if let image = image {
            if let imageData = image.pngData() {
                multipart.add(
                    key: "image",
                    fileName: "image.png",
                    fileMimeType: "image/png",
                    fileData: imageData
                )
            } else if let imageData = image.jpegData(compressionQuality: 0.8) {
                multipart.add(
                    key: "image",
                    fileName: "image.jpg",
                    fileMimeType: "image/jpeg",
                    fileData: imageData
                )
            } else {
                print("Error: Unable to process image as PNG or JPEG.")
                return
            }
        } else {
            print("Error: Image is required but not provided.")
            return
        }

        // Debug: Log the request payload
        print("Request Payload:")
        print("Username: \(username)")
        print("Type: \(selectedCategory?.uppercased() ?? "")")
        print("Fit: \(selectedFit ?? "")")
        print("Occasion: \(selectedOccasion ?? "")")
        print("Winter: \(selectedWeather == "WINTER" ? "True" : "False")")
        print("Primary Color: \(primaryRGB)")
        print("Secondary Color: \(secondaryRGB)")
        print("Subtype: \(selectedSubtype ?? "None")")
        print("Precipitation: \(selectedPrecip ?? "None")")
        print("Tags: \(tags.joined(separator: ","))")
        print("Image: \(image != nil ? "Attached" : "None")")

        // Create a regular HTTP URL request & use multipart components
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

            if let httpResponse = response as? HTTPURLResponse {
                print("Response status code: \(httpResponse.statusCode)")
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString)")
            }

            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    showSuccessSnackbar = true
                    clearForm()
                    // Wait for snackbar animation before navigating
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        navigateToWardrobe = true
                        showSuccessSnackbar = false
                    }
                }
                isLoading = false
            }
        }.resume()
    }

    func clearForm() {
        image = nil
        tags = []
        newTag = ""
        selectedCategory = nil
        selectedSubtype = nil
        selectedFit = nil
        selectedOccasion = nil
        selectedPrecip = nil
        selectedWeather = nil
        primaryColor = RGBColor(red: 128, green: 128, blue: 128)
        secondaryColor = RGBColor(red: 128, green: 128, blue: 128)
    }

    func processImageForColors(_ image: UIImage) {
        isProcessingImage = true
        var multipart = MultipartRequest()
        multipart.add(key: "username", value: username)

        multipart.add(
            key: "image",
            fileName: "clothing.png",
            fileMimeType: "image/png",
            fileData: image.pngData()!
        )

        guard let url = URL(string: "\(urlStore.serverUrl)/image/process") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(multipart.httpContentTypeHeadeValue, forHTTPHeaderField: "Content-Type")
        request.httpBody = multipart.httpBody

        // Process in background without blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Image process error: \(error)")
                    return
                }

                guard let data = data else { return }
                
                print("Raw response: \(String(data: data, encoding: .utf8) ?? "N/A")")

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let colorArrayString = json["colors"] as? String,
                       let colorData = colorArrayString.data(using: .utf8),
                       let colors = try? JSONDecoder().decode([[Int]].self, from: colorData),
                       let base64String = json["image_base64"] as? String,
                       let processedImageData = Data(base64Encoded: base64String),
                       let processedImage = UIImage(data: processedImageData) {

                        DispatchQueue.main.async {
                            self.image = processedImage

                            // Set primary color
                            if let rgb1 = colors.first, rgb1.count == 3 {
                                self.primaryColor = RGBColor(red: rgb1[0], green: rgb1[1], blue: rgb1[2])
                            }

                            // Set secondary color
                            if let rgb2 = colors.dropFirst().first, rgb2.count == 3 {
                                self.secondaryColor = RGBColor(red: rgb2[0], green: rgb2[1], blue: rgb2[2])
                            }

                            print("Primary color: \(colors.first ?? [])")
                            print("Secondary color: \(colors.dropFirst().first ?? [])")
                            isProcessingImage = false
                        }
                    }
                } catch {
                    print("Failed to decode response: \(error)")
                    isProcessingImage = false
                }
            }.resume()
        }
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
                parent.image = image
                parent.onImageSelected(image)  // Process background removal in background
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
