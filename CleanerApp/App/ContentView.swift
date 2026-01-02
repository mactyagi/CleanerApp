//
//  ContentView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        // Note: Currently not used - RootView uses TabBarControllerWrapper to display
        // the existing UIKit TabBarController. This view will be used later when
        // individual tabs are migrated to SwiftUI.
        TabView(selection: $appState.selectedTab) {
            // MARK: - Home Tab
            NavigationStack {
                PlaceholderView(title: "Home")
            }
            .tabItem {
                Label("Home", systemImage: appState.selectedTab == .home ? "house.fill" : "house")
            }
            .tag(TabSelection.home)

            // MARK: - Video Compressor Tab
            NavigationStack {
                PlaceholderView(title: "Video Compressor")
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

// MARK: - Placeholder View (temporary, will be replaced by actual screens)
struct PlaceholderView: View {
    let title: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text("Coming Soon")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(AppearanceManager())
}
