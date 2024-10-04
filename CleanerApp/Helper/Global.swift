//
//  Common.swift
//  CleanerApp
//
//  Created by Manukant Tyagi on 28/07/24.
//

import Foundation
import UIKit

let generator = UIImpactFeedbackGenerator(style: .rigid)

func vibrate() {
    generator.prepare()
    generator.impactOccurred()
}

func getDeviceIdentifier() -> String? {
    if let uuid = UIDevice.current.identifierForVendor?.uuidString {
        return uuid
    }
    return nil
}

func isRunningInPreview() -> Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

enum ConstantString: String {
    case selectAll = "Select All"
    case deSelectAll = "Deselect All"
    case select = "Select"
    case cancel = "Cancel"
    case delete = "Delete"
    case contacts = "Contacts"
    case contact = "Contact"
    case back = "Back"
    case selected = "Selected"
    case calendar = "Calendar"
    case reminder = "Reminder"
    case events = "Events"
    case event = "Event"
    case similars = "Similars"
    case duplicates = "Duplicates"
    case others = "Others"
    case screenRecordings = "Screen Recordings"
    case allVideos = "All Videos"
}

enum UserDefaultKeys: String {
    
    case appearance = "appearanceMode"
}
