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
    var currentState: Int
    var votedUsers: [String]
    var featureTitle: String
    var featureDescription: String
    var createdAt: String
    var updatedAt: String
    var createdBy: String
}
