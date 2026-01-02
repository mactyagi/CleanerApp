//
//  ContentView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI

struct TabBarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // MARK: - Home Tab
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: appState.selectedTab == .home ? "house.fill" : "house")
            }
            .tag(TabSelection.home)

            // MARK: - Video Compressor Tab
            NavigationStack {
                VideoCompressorView()
            }
            .tabItem {
                Label(
                    "Compressor",
                    systemImage: appState.selectedTab == .compressor
                        ? "digitalcrown.horizontal.press.fill"
                        : "digitalcrown.horizontal.press"
                )
            }
            .tag(TabSelection.compressor)

            // MARK: - Settings Tab
            NavigationStack {
                SettingView()
            }
            .tabItem {
                Label(
                    "Settings",
                    systemImage: appState.selectedTab == .settings ? "gear.circle.fill" : "gear.circle"
                )
            }
            .tag(TabSelection.settings)
        }
    }
}

#Preview {
    TabBarView()
        .environmentObject(AppState())
        .environmentObject(AppearanceManager())
}
