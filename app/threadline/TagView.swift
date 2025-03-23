//
//  TagView.swift
//  threadline
//
//  Created by Andy Yang on 3/10/25.
//

import SwiftUI

struct TagView: View {
    @AppStorage("username") private var username: String = ""
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var clothingType: String = ""
    @State private var subtype: String = ""
    @State private var fit: String = ""
    @State private var layerable: Bool = false
    @State private var precip: String = ""
    @State private var occasion: String = ""
    @State private var winter: Bool = false
    let image: UIImage

    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .padding()

            PickerView(title: "Clothing Type", selection: $clothingType, options: MetadataOptions.clothingTypes)
                .padding()

            if let subtypes = getSubtypes(for: clothingType) {
                PickerView(title: "Subtype", selection: $subtype, options: subtypes)
                    .padding()
            }

            PickerView(title: "Fit", selection: $fit, options: MetadataOptions.fits)
                .padding()

            Toggle("Layerable", isOn: $layerable)
                .padding()

            PickerView(title: "Precipitation", selection: $precip, options: MetadataOptions.precipOptions)
                .padding()

            PickerView(title: "Occasion", selection: $occasion, options: MetadataOptions.occasions)
                .padding()

            Toggle("Winter", isOn: $winter)
                .padding()

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
                uploadClothingItem()
            }) {
                Text("Done")
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(username.isEmpty || clothingType.isEmpty || fit.isEmpty || occasion.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            .disabled(username.isEmpty || clothingType.isEmpty || fit.isEmpty || occasion.isEmpty)
        }
    }

    func getSubtypes(for type: String) -> [String]? {
        switch type.lowercased() {
        case "top":
            return MetadataOptions.topSubtypes
        case "bottom":
            return MetadataOptions.bottomSubtypes
        case "outerwear":
            return MetadataOptions.outerwearSubtypes
        case "dress":
            return MetadataOptions.dressSubtypes
        case "shoes":
            return MetadataOptions.shoesSubtypes
        default:
            return nil
        }
    }

    func uploadClothingItem() {
        guard let url = URL(string: "http://your-backend-url/clothing/create") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add image data
        if let imageData = image.jpegData(compressionQuality: 0.7) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        // Add other fields
        let fields: [String: String] = [
            "username": username,
            "type": clothingType.uppercased(),
            "subtype": subtype.uppercased(),
            "fit": fit.uppercased(),
            "layerable": layerable ? "true" : "false",
            "precip": precip.uppercased(),
            "occasion": occasion.uppercased(),
            "winter": winter ? "true" : "false"
        ]

        for (key, value) in fields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        // Add tags
        for tag in tags {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"tags\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(tag)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }

            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                print("Success")
            } else {
                print("Failed")
            }
        }.resume()
    }
}

struct PickerView: View {
    var title: String
    @Binding var selection: String
    var options: [String]

    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(option).tag(option)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
}

struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        TagView(image: UIImage(named: "sampleImage") ?? UIImage())
    }
}
