//
//  SettingModel.swift
//  CleanerApp
//
//  Created by manukant tyagi on 17/09/24.
//

import Foundation

enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

enum SettingType: String, CaseIterable {
    case privacyPolicy
    case appearance
    case featureRequest
    case followMe
    case contactUS
    case reportAnError
    case refferAFriend
    case leaveReview
    
    var model: SettingModel {
        switch self {
            
        case .privacyPolicy:
            return SettingModel(title: "Privacy Policy", subTitle: "")
        case .appearance:
            return SettingModel(title: "Appearance", subTitle: "")
        case .featureRequest:
            return SettingModel(title: "Feature Request", subTitle: "Suggest and Vote for your favourite features")
        case .followMe:
            return SettingModel(title: "Follow Me", subTitle: "Let's Connect on Linkedin")
        case .contactUS:
            return SettingModel(title: "Contact Us", subTitle: "")
        case .reportAnError:
            return SettingModel(title: "Report an Error", subTitle: "3 hr response")
        case .refferAFriend:
            return SettingModel(title: "Refer a friend", subTitle: "")
        case .leaveReview:
            return SettingModel(title: "Rate the app🤩", subTitle: "Help me grow the app by leaving a good review.")
        }
    }
    
}


struct SettingModel{
    var title: String
    var subTitle: String
}

