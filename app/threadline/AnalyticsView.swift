//
//  AnalyticsView.swift
//  threadline
//
//  Created by Ryan Stephen on 3/22/25.
//

import SwiftUI

// Models for decoding the API response
struct UtilizationData: Codable {
    let TOTAL: String?
    let TOP: String?
    let BOTTOM: String?
    let OUTERWEAR: String?
    let DRESS: String?
    let SHOES: String?
    
    // Computed properties to convert strings to Doubles
    var totalValue: Double { Double(TOTAL ?? "0") ?? 0 }
    var topValue: Double { Double(TOP ?? "0") ?? 0 }
    var bottomValue: Double { Double(BOTTOM ?? "0") ?? 0 }
    var outerwearValue: Double { Double(OUTERWEAR ?? "0") ?? 0 }
    var dressValue: Double { Double(DRESS ?? "0") ?? 0 }
    var shoesValue: Double { Double(SHOES ?? "0") ?? 0 }
}

struct RewornItem: Codable {
    let id: Int
    let img_filename: String
    let wears: Int
}

struct RewearData: Codable {
    let TOP: [RewornItem]?
    let BOTTOM: [RewornItem]?
    let OUTERWEAR: [RewornItem]?
    let DRESS: [RewornItem]?
    let SHOES: [RewornItem]?
}

struct UtilizationResponse: Codable {
    let utilization: UtilizationData
    let rewears: RewearData
}

struct AnalyticsView: View {
    @AppStorage("username") private var username: String = ""
    @Environment(UrlStore.self) private var urlStore
    
    @State private var utilization: UtilizationData?
    @State private var rewears: RewearData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    } else {
                        // Utilization Section
                        if let utilization = utilization {
                            utilizationSection(utilization)
                        }
                        
                        // Most Reworn Section
                        if let rewears = rewears {
                            rewornSection(rewears)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Wardrobe Analytics")
            .refreshable {
                await fetchStats()
            }
        }
        .onAppear {
            Task {
                await fetchStats()
            }
        }
    }
    
    private func utilizationSection(_ utilization: UtilizationData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Utilization")
                .font(.headline)
            
            if isAllZeroOrNull(utilization) {
                Text("No outfits logged this month")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                utilizationRow("Total Wardrobe", utilization.totalValue)
                utilizationRow("Tops", utilization.topValue)
                utilizationRow("Bottoms", utilization.bottomValue)
                utilizationRow("Outerwear", utilization.outerwearValue)
                utilizationRow("Dresses", utilization.dressValue)
                utilizationRow("Shoes", utilization.shoesValue)
            }
            .padding(.horizontal)
        }
    }
    
    private func rewornSection(_ rewears: RewearData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Most Worn Items")
                .font(.headline)
            
            if isAllEmpty(rewears) {
                Text("No items have been worn multiple times this month")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    if let topRewear = rewears.TOP?.first {
                        rewornItemRow("Top", topRewear)
                    }
                    if let bottomRewear = rewears.BOTTOM?.first {
                        rewornItemRow("Bottom", bottomRewear)
                    }
                    if let outerwearRewear = rewears.OUTERWEAR?.first {
                        rewornItemRow("Outerwear", outerwearRewear)
                    }
                    if let dressRewear = rewears.DRESS?.first {
                        rewornItemRow("Dress", dressRewear)
                    }
                    if let shoesRewear = rewears.SHOES?.first {
                        rewornItemRow("Shoes", shoesRewear)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func utilizationRow(_ label: String, _ value: Double) -> some View {
        HStack {
            Text(label)
            Spacer()
            // Create a progress bar with the percentage
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 20)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(value > 0 ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: max(4, 100 * CGFloat(value)), height: 20)
                
                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.leading, 4)
            }
        }
    }
    
    private func rewornItemRow(_ category: String, _ item: RewornItem) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: "\(urlStore.r2BucketUrl)\(item.img_filename)")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Worn \(item.wears) times this month")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func fetchStats() async {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(urlStore.serverUrl)/utilization/get?username=\(username)") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            guard httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let decoder = JSONDecoder()
            let result = try decoder.decode(UtilizationResponse.self, from: data)
            
            self.utilization = result.utilization
            self.rewears = result.rewears
            
        } catch {
            errorMessage = "Failed to load stats: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func isAllZeroOrNull(_ utilization: UtilizationData) -> Bool {
        return utilization.totalValue == 0 &&
               utilization.topValue == 0 &&
               utilization.bottomValue == 0 &&
               utilization.outerwearValue == 0 &&
               utilization.dressValue == 0 &&
               utilization.shoesValue == 0
    }
    
    private func isAllEmpty(_ rewears: RewearData) -> Bool {
        return rewears.TOP == nil &&
               rewears.BOTTOM == nil &&
               rewears.OUTERWEAR == nil &&
               rewears.DRESS == nil &&
               rewears.SHOES == nil
    }
}

#Preview {
    AnalyticsView()
}
