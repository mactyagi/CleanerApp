//
//  AppearanceManager.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI

@MainActor
class AppearanceManager: ObservableObject {
    // Uses existing AppearanceMode enum from SettingModel.swift
    @Published var appearanceMode: AppearanceMode = .system {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: UserDefaultKeys.appearance.rawValue)
        }
    }

    init() {
        let savedValue = UserDefaults.standard.string(forKey: UserDefaultKeys.appearance.rawValue) ?? ""
        appearanceMode = AppearanceMode(rawValue: savedValue) ?? .system
    }

    var colorScheme: ColorScheme? {
        switch appearanceMode {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    func setAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
    }
}
