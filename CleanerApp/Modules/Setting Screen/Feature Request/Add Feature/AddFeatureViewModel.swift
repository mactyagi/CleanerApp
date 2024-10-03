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
        let userUDID = getDeviceIdentifier() ?? ""
        let feature = Feature(
            currentState: .userRequested,
            votedUsers: [userUDID],
            featureTitle: title,
            featureDescription: description,
            createdAt: Date().toString(),
            updatedAt: Date().toString(),
            createdBy: userUDID)
        
        if isRunningInPreview(){ return }
        FireStoreManager().addFeatureInFeatureRequest(feature: feature) { success in
            completion(success)
        }
    }
}
