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

    let size: Double = 100
    let item: LogOutfitItem

    var body: some View {
        ZStack() {
            AsyncImage(url: URL(string: "\(urlStore.r2BucketUrl)\(item.img_filename)")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                } else if phase.error != nil {
                    Color.red // display an error placeholder
                } else {
                    ProgressView()
                }
            }
            .frame(width: size, height: size)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .accessibility(label: Text(isSelected ? "Checked" : "Unchecked"))
                .imageScale(.large)
                .padding([.bottom, .trailing], 7)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.gray.opacity(0.25), radius: 5, x: 0, y: 2)
        .padding(.top, 10)
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
