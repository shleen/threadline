//
//  TagView.swift
//  threadline
//
//  Created by Andy Yang on 3/10/25.
//

import SwiftUI

struct TagView: View {
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var selectedCategory: String? = nil
    let image: UIImage

    let categories = ["Top", "Bottom", "Outerwear", "Dress", "Shoe"]

    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 200)
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
                print("Tags: \(tags)")
                print("Selected Category: \(selectedCategory ?? "None")")
            }) {
                Text("Done")
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(selectedCategory == nil ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            .disabled(selectedCategory == nil)
        }
    }
}

struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        TagView(image: UIImage(named: "sampleImage") ?? UIImage())
    }
}
