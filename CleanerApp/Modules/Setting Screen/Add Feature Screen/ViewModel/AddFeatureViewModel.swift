//
//  AddFeatureViewModel.swift
//  CleanerApp
//
//  Created by manukant tyagi on 18/09/24.
//

import SwiftUI
import Foundation
import Combine


class AddFeatureViewModel: ObservableObject {
    // MARK: - Constraints
    let minTitleLength: Int = 4
    let maxTitleLength: Int = 80
    let minDescriptionLength: Int = 10
    let maxDescriptionLength: Int = 500
    
    // MARK: - Inputs
    @Published var title: String = "" {
        didSet {
            if title.count > maxTitleLength { title = String(title.prefix(maxTitleLength)) }
            validate()
            updateSuggestions()
        }
    }
    @Published var description: String = "" {
        didSet {
            if description.count > maxDescriptionLength { description = String(description.prefix(maxDescriptionLength)) }
            validate()
        }
    }
    
    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var showCompletionAlert: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var isFormValid: Bool = false
    
    // MARK: - Suggestions
    @Published private(set) var existingFeatures: [Feature] = []
    @Published private(set) var suggestedFeatures: [Feature] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupValidation()
    }
    
    convenience init(existingFeatures: [Feature]) {
        self.init()
        self.existingFeatures = existingFeatures
        self.updateSuggestions()
    }
    
    func preloadExistingFeatures() {
        FireStoreManager().fetchFeatures { [weak self] features in
            self?.existingFeatures = features
            self?.updateSuggestions()
        }
    }
    
    // Use this to inject already-fetched features and avoid refetching
    func setExistingFeatures(_ features: [Feature]) {
        existingFeatures = features
        updateSuggestions()
    }
    
    private func setupValidation() {
        // Keep Combine-based validation to react to changes and external updates
        Publishers.CombineLatest($title, $description)
            .map { [weak self] title, description in
                guard let self = self else { return false }
                return title.trimmingCharacters(in: .whitespacesAndNewlines).count >= self.minTitleLength &&
                title.count <= self.maxTitleLength &&
                description.trimmingCharacters(in: .whitespacesAndNewlines).count >= self.minDescriptionLength &&
                description.count <= self.maxDescriptionLength
            }
            .assign(to: \.isFormValidBacking, on: self)
            .store(in: &cancellables)
    }
    
    // Backing storage so we can also call validate() explicitly
    private var isFormValidBacking: Bool = false {
        didSet { isFormValid = isFormValidBacking }
    }
    
    private func validate() {
        isFormValidBacking = title.trimmingCharacters(in: .whitespacesAndNewlines).count >= minTitleLength &&
        title.count <= maxTitleLength &&
        description.trimmingCharacters(in: .whitespacesAndNewlines).count >= minDescriptionLength &&
        description.count <= maxDescriptionLength
    }
    
    private func updateSuggestions() {
        let query = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard query.count >= 3 else { suggestedFeatures = []; return }
        suggestedFeatures = existingFeatures
            .filter { feature in
                feature.currentState != .completed &&
                (feature.featureTitle.lowercased().contains(query) || feature.featureDescription.lowercased().contains(query))
            }
            .sorted { $0.votedUsers.count > $1.votedUsers.count }
            .prefix(3)
            .map { $0 }
    }
    
    func submitFeature(completion: @escaping () -> Void) {
        isLoading = true
        
        sendFeatureToFirebase { [weak self] success in
            guard let self = self else { return }
            
            self.isLoading = false
            if success {
                self.showCompletionAlert = true
            } else {
                self.showErrorAlert = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                completion()
            }
        }
    }
    
    func sendFeatureToFirebase(completion: @escaping (_ success: Bool) -> () ) {
        let now = Date()
        let feature = Feature(
            currentState: .userRequested,
            votedUsers: [UIDevice.deviceId],
            featureTitle: title.trimmingCharacters(in: .whitespacesAndNewlines),
            featureDescription: description.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: formatISODate(now),
            updatedAt: formatISODate(now),
            createdBy: UIDevice.deviceId)
        
        if isRunningInPreview() { 
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                completion(true)
            }
            return 
        }
        
        FireStoreManager().addFeatureInFeatureRequest(feature: feature) { success in
            completion(success)
        }
    }
    
    func resetAlerts() {
        showCompletionAlert = false
        showErrorAlert = false
    }
    
    private func formatISODate(_ date: Date) -> String {
        ISO8601DateFormatter.cached.string(from: date)
    }
    
    private func isRunningInPreview() -> Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
