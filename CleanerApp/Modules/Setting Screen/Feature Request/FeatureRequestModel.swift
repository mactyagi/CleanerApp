//
//  FeatureRequestModel.swift
//  CleanerApp
//
//  Created by manukant tyagi on 18/09/24.
//

import Foundation
import FirebaseFirestore

struct Feature: Codable {
    @DocumentID var id: String?
    var currentState: FeatureState
    var votedUsers: Set<String>
    var featureTitle: String
    var featureDescription: String
    var createdAt: String
    var updatedAt: String
    var createdBy: String
    
    var hasCurrentUserVoted: Bool {
       votedUsers.contains(getDeviceIdentifier() ?? "")
    }
}

enum FeatureState: String, Codable {
    case userRequested
    case open
    case building
    case completed
}
