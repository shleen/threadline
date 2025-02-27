//
//  LogOutfitItemView.swift
//  threadline
//
//  Created by sheline on 1/27/25.
//

import SwiftUI

struct LogOutfitItemView: View {
    @Binding var selectedItems: Set<Int>

    let size: Double
    let item: LogOutfitItem

    @State private var isSelected = false

    var body: some View {
        VStack() {
            Text(item.item)
                .frame(width: size, height: size)
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
