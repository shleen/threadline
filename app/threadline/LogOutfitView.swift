//
//  LogOutfitView.swift
//  threadline
//
//  Created by sheline on 1/27/25.
//

import SwiftUI

// TODO: Update after integrating with backend
struct LogOutfitItem: Identifiable {
    let id: Int
    let item: String
}

struct LogOutfitView: View {
    @Binding var isPresented: Bool

    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: 3)
    @State private var selectedItems: Set<Int> = []

    // TODO: Integrate with backend - call /closet/get
    var items = [
        LogOutfitItem(id: 1, item: "one"),
        LogOutfitItem(id: 2, item: "two"),
        LogOutfitItem(id: 3, item: "three"),
        LogOutfitItem(id: 4, item: "four"),
        LogOutfitItem(id: 5, item: "five")
    ]

    func saveOutfit() {
        // TODO: Save outfit - post to /outfit/post
        print(selectedItems)

        isPresented.toggle()
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("What are you wearing today?")
                .font(.system(size: 18, weight: .regular))
            ScrollView {
                LazyVGrid(columns: gridColumns) {
                    ForEach(items) { item in
                        LogOutfitItemView(selectedItems: $selectedItems, size: 50, item: item)
                    }
                }
            }
        }
        .toolbar {
            Button(action: saveOutfit) {
                Text("Done")
            }
            .disabled(selectedItems.isEmpty)
        }
    }
}
