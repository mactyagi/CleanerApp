//
//  SettingViewModel.swift
//  CleanerApp
//
//  Created by manukant tyagi on 17/09/24.
//

import SwiftUI

class SettingViewModel:ObservableObject{
    @AppStorage(UserDefaultKeys.appearance.rawValue) private var appearanceModeRawValue:String = AppearanceMode.system.rawValue
    
    
    var  sections: [(header:String, items: [SettingType])] = [
        ("Customization", [.appearance]),
        ("Support", [.featureRequest, .contactUS, .reportAnError]),
        ("Support an Indie Developer", [.leaveReview, .followMe]),
        ("More", [.refferAFriend, .privacyPolicy])
        ]
        
        
    var appearanceMode: AppearanceMode {
        get {
            AppearanceMode(rawValue: appearanceModeRawValue) ?? .system
        }
        set {
            appearanceModeRawValue = newValue.rawValue
        }
    }
}

