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
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var isLoading: Bool = false
    @Published var showCompletionAlert: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var isFormValid: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupValidation()
    }
    
    private func setupValidation() {
        Publishers.CombineLatest($title, $description)
            .map { title, description in
                return !title.isEmpty && !description.isEmpty
            }
            .assign(to: \.isFormValid, on: self)
            .store(in: &cancellables)
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
        let feature = Feature(
            currentState: .userRequested,
            votedUsers: [UIDevice.deviceId],
            featureTitle: title,
            featureDescription: description,
            createdAt: formatDate(Date()),
            updatedAt: formatDate(Date()),
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func isRunningInPreview() -> Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
