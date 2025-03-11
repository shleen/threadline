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
    let image: UIImage

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

            ScrollView(.horizontal) {
                HStack {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(16)
                            .padding(.horizontal, 4)
                    }
                }
                .padding()
            }

            Spacer()

            Button(action: {
                // Handle done action
                print("Tags: \(tags)")
            }) {
                Text("Done")
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
}

struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        TagView(image: UIImage(named: "sampleImage") ?? UIImage())
    }
}