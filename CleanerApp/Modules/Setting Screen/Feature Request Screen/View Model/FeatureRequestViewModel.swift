//
//  FeatureRequestViewModel.swift
//  CleanerApp
//
//  Created by manukant tyagi on 29/09/24.
//

import SwiftUI


class FeatureRequestViewModel: ObservableObject {
    
    private var allData: [Feature] = []
    @Published var list : [Feature] = [] {
        didSet {
            showLoader = false
        }
    }
    @Published var showLoader: Bool = true
    @Published var selectedSegment: FeatureSegmentType = .open {
        didSet{
            applyFiltersAndSort()
        }
    }
    
    // MARK: - Search / Sort / Error
    @Published var searchText: String = "" {
        didSet { applyFiltersAndSort() }
    }
    
    enum SortOption: String, CaseIterable {
        case mostVoted
        case newest
        case recentlyUpdated
        
        var title: String {
            switch self {
            case .mostVoted: return "Most Voted"
            case .newest: return "Newest"
            case .recentlyUpdated: return "Recently Updated"
            }
        }
    }
    
    @Published var sort: SortOption = .mostVoted {
        didSet { applyFiltersAndSort() }
    }
    
    @Published var errorMessage: String? = nil
    @Published var inFlightVoteIds: Set<String> = []
    
    init(isMockData: Bool = false) {
        if  isMockData {
            getMockData()
        }else {
            getData()
        }
    }
    
    
    func getMockData() {
        allData = Feature.mockFeatures()
        applyFiltersAndSort()
    }
    
    func getData() {
        showLoader = true
        FireStoreManager().fetchFeatures { features in
            self.allData = features
            self.applyFiltersAndSort()
            self.showLoader = false
        }
    }
    
    // MARK: - Filtering & Sorting
    func applyFiltersAndSort() {
        // Segment filter
        var filtered: [Feature]
        switch selectedSegment {
        case .open:
            filtered = allData.filter { $0.currentState == .open }
        case .building:
            filtered = allData.filter { $0.currentState == .building }
        case .done:
            filtered = allData.filter { $0.currentState == .completed }
        }
        
        // Search filter
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            let lower = trimmedQuery.lowercased()
            filtered = filtered.filter { feature in
                feature.featureTitle.lowercased().contains(lower) ||
                feature.featureDescription.lowercased().contains(lower)
            }
        }
        
        // Sort
        switch sort {
        case .mostVoted:
            filtered.sort { $0.votedUsers.count > $1.votedUsers.count }
        case .newest:
            filtered.sort { (parseISO8601($0.createdAt) ?? .distantPast) > (parseISO8601($1.createdAt) ?? .distantPast) }
        case .recentlyUpdated:
            filtered.sort { (parseISO8601($0.updatedAt) ?? .distantPast) > (parseISO8601($1.updatedAt) ?? .distantPast) }
        }
            list = filtered
    }
    
    // MARK: - Voting (Optimistic)
    func toggleVote(for feature: Feature) {
        guard let featureId = feature.id else { return }
        
        if inFlightVoteIds.contains(featureId) { return }
        inFlightVoteIds.insert(featureId)
        
        // Optimistic local update in allData
        if let indexInAll = allData.firstIndex(where: { $0.id == featureId }) {
            var updated = allData[indexInAll]
            if updated.hasCurrentUserVoted {
                updated.votedUsers.remove(UIDevice.deviceId)
            } else {
                updated.votedUsers.insert(UIDevice.deviceId)
            }
            allData[indexInAll] = updated
        }
        
        // Reflect in current list
        withAnimation(.easeInOut(duration: 0.2)) {
            applyFiltersAndSort()
        }
        
        
        // Persist
        let featureToPersist = allData.first(where: { $0.id == featureId }) ?? feature
        FireStoreManager().updateFeature(feature: featureToPersist) { success in
            DispatchQueue.main.async {
                if !success {
                    // Rollback
                    if let indexInAll = self.allData.firstIndex(where: { $0.id == featureId }) {
                        var reverted = self.allData[indexInAll]
                        if reverted.hasCurrentUserVoted {
                            reverted.votedUsers.remove(UIDevice.deviceId)
                        } else {
                            reverted.votedUsers.insert(UIDevice.deviceId)
                        }
                        self.allData[indexInAll] = reverted
                    }
                    self.errorMessage = "Update feature failed"
                    logErrorString(errorString: "Update feature failed", VCName: "FeatureRequestViewModel", functionName: #function, line: #line)
                }
                self.inFlightVoteIds.remove(featureId)
                self.applyFiltersAndSort()
            }
        }
    }
    
    // MARK: - Helpers
    private func parseISO8601(_ string: String) -> Date? {
        ISO8601DateFormatter.cached.date(from: string)
    }
}

extension ISO8601DateFormatter {
    static let cached: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}
