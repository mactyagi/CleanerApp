import Foundation
import FirebaseFirestore

enum ErrorCategory: String, Codable, CaseIterable {
    case crash = "Crash"
    case uiBug = "UI Bug"
    case dataIssue = "Data Issue"
    case other = "Other"
}

enum ErrorArea: String, Codable, CaseIterable {
    case photos = "Photos"
    case contacts = "Contacts"
    case calendar = "Calendar"
    case compression = "Compression"
    case other = "Other"
}

struct ErrorReport: Codable {
    @DocumentID var id: String?
    var category: ErrorCategory
    var area: ErrorArea
    var errorTitle: String
    var errorDescription: String
    var deviceModel: String
    var iosVersion: String
    var appVersion: String
    var screenshots: [String]
    var reportedAt: String
    var reportedBy: String
}
