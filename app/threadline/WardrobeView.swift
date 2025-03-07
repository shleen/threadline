//
//  WardrobeView.swift
//  threadline
//
//  Created by James Choi on 3/6/25.
//

import SwiftUI

struct WardrobeView: View {
    //Todo get images from backend using database
    let images = ["image1", "image2", "image3", "image4", "image5", "image6"]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        //View of outfits in a 3 column view
        //Todo add more styling later
        //TODO add ability to tap specific outfits to see details
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

struct WardrobeView_Previews: PreviewProvider {
    static var previews: some View {
        WardrobeView()
    }
}
