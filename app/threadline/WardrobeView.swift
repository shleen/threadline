//
//  WardrobeView.swift
//  threadline
//
//  Created by James Choi on 3/6/25.
//

import SwiftUI

struct WardrobeView: View {
    //Todo get images from backend using database
    //let images = ["image1", "image2", "image3", "image4", "image5", "image6"]
    let images = ["Example", "Sweats", "Example", "Example", "Example"]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @State private var selectedTab = "All"
    let tabs = ["All", "Tagged"]
    
    var body: some View {
        //View of outfits in a 3 column view
        //TODO Change images presented based on the tab
        VStack {
            //Header with tabs
            Picker("Select Tab", selection: $selectedTab) {
                ForEach(tabs, id: \..self) { tab in
                    Text(tab).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .background(Color.gray)
            .foregroundColor(.white)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(images, id: \..self) { image in
                        Image(image)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
    }
}
