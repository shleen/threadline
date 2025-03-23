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
    @State private var selectedSubtype: String? = nil
    @State private var selectedFit: String? = nil
    @State private var selectedOccasion: String? = nil
    @State private var selectedPrecip: String? = nil
    @State private var isWinter: Bool? = nil
    let image: UIImage

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
                    Text("Select Winter Option").tag(Bool?.none)
                    ForEach(winterOptions, id: \.self) { option in
                        Text(option).tag(option == "Winter" ? Bool?.some(true) : Bool?.some(false))
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
                print("Tags: \(tags)")
                print("Selected Category: \(selectedCategory ?? "None")")
                print("Selected Subtype: \(selectedSubtype ?? "None")")
                print("Selected Fit: \(selectedFit ?? "None")")
                print("Selected Occasion: \(selectedOccasion ?? "None")")
                print("Selected Precipitation: \(selectedPrecip ?? "None")")
                print("Winter: \(isWinter == true ? "Yes" : "No")")
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
}

struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        TagView(image: UIImage(named: "sampleImage") ?? UIImage())
    }
}