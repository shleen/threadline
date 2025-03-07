//
//  LogOutfitItemView.swift
//  threadline
//
//  Created by sheline on 1/27/25.
//

import SwiftUI

struct LogOutfitItemView: View {
    @Binding var selectedItems: Set<Int>

    @Environment(UrlStore.self) private var urlStore

    @State private var isSelected = false

    let size: Double = 64
    let item: LogOutfitItem

    var body: some View {
        VStack() {
            AsyncImage(url: URL(string: "\(urlStore.r2BucketUrl)\(item.img_filename)")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else if phase.error != nil {
                    Color.red // display an error placeholder
                } else {
                    ProgressView()
                }
            }
            .frame(width: size, height: size)
            .clipped()

            HStack() {
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .accessibility(label: Text(isSelected ? "Checked" : "Unchecked"))
                    .imageScale(.large)
            }
        }
        .onTapGesture {
            isSelected.toggle()

            if isSelected {
                // Add self to selected items
                selectedItems.insert(item.id)
            }
            else {
                // Remove self from selected items
                selectedItems.remove(item.id)
            }
        }
    }
}
