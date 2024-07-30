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
}
