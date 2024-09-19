//
//  AddFeatureViewModel.swift
//  CleanerApp
//
//  Created by manukant tyagi on 18/09/24.
//

import SwiftUI


class AddFeatureViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    
    
    
    func sendFeatureToFirebase(completion: @escaping (_ success: Bool) -> () ) {
        let feature = Feature(
            currentState: 0,
            votedUsers: ["self"],
            featureTitle: title,
            featureDescription: description,
            createdAt: Date().toString(),
            updatedAt: Date().toString(),
            createdBy: "Self")
        if isRunningInPreview(){ return }
        FireStoreManager().addFeatureInFeatureRequest(feature: feature) { success in
            completion(success)
        }
    }
}
