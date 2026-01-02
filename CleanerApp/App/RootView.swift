//
//  RootView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appearanceManager: AppearanceManager
    @State private var showLaunch = true

    var body: some View {
        ZStack {
            if showLaunch {
                LaunchView(onComplete: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showLaunch = false
                    }
                })
                .transition(.opacity)
            } else {
                TabBarView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(appearanceManager.colorScheme)
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
        .environmentObject(AppearanceManager())
}
