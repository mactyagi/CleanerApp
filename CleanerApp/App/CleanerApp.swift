//
//  CleanerApp.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI
import FirebaseCore

@main
struct CleanerApp: App {
    // Delegate adaptor to use AppDelegate for Firebase initialization
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // App-level state management
    @StateObject private var appState = AppState()
    @StateObject private var appearanceManager = AppearanceManager()

    // Scene phase monitoring
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(appearanceManager)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
                }
        }
    }

    // MARK: - Scene Phase Handling

    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // Resume background tasks
            CoreDataPHAssetManager.shared.startProcessingPhotos()
            logEvent(Event.appEnterForeground.rawValue, parameter: nil)

        case .background:
            // Log background event
            logEvent(Event.appEnterBackground.rawValue, parameter: nil)

        case .inactive:
            // App is becoming inactive (phone call, etc.)
            break

        @unknown default:
            break
        }
    }
}
