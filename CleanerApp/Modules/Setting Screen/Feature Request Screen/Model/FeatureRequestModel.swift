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



extension Feature {
    static func  mockFeatures() -> [Feature] {
        [
            Feature(
                id: "feature_001",
                currentState: .userRequested,
                votedUsers: ["device_123", "device_456"],
                featureTitle: "Export to PDF",
                featureDescription: "Allow users to export data as PDF for sharing.",
                createdAt: "2025-04-10T08:00:00Z",
                updatedAt: "2025-04-10T08:00:00Z",
                createdBy: "user_001"
            ),
            Feature(
                id: "feature_002",
                currentState: .open,
                votedUsers: ["device_789"],
                featureTitle: "Auto-Clean Scheduler",
                featureDescription: "Let users schedule regular auto-cleanups.",
                createdAt: "2025-03-20T09:00:00Z",
                updatedAt: "2025-03-25T10:30:00Z",
                createdBy: "user_002"
            ),
            Feature(
                id: "feature_003",
                currentState: .building,
                votedUsers: ["device_123", "device_789"],
                featureTitle: "Language Support",
                featureDescription: "Support for Hindi, Spanish, and French languages.",
                createdAt: "2025-02-18T10:15:00Z",
                updatedAt: "2025-04-01T07:45:00Z",
                createdBy: "admin"
            ),
            Feature(
                id: "feature_004",
                currentState: .completed,
                votedUsers: ["device_111", "device_222", "device_333"],
                featureTitle: "Face ID Lock",
                featureDescription: "Secure the app with Face ID or Touch ID.",
                createdAt: "2025-01-10T12:00:00Z",
                updatedAt: "2025-03-01T16:00:00Z",
                createdBy: "user_003"
            )
        ]
    }
}


enum FeatureState: String, Codable {
    case userRequested
    case open
    case building
    case completed
}



