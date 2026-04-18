//
//  TabBarController.swift
//  CleanerApp
//
//  Created by Manukant Tyagi on 17/08/24.
//

import Foundation
import SwiftUI

// MARK: - SwiftUI Main Tab View
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeNavigationView()
                .tabItem {
                    Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            // Settings Tab
            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 1 ? "gear.circle.fill" : "gear.circle")
                }
                .tag(1)
        }
        .tint(.blue)
    }
}

// MARK: - Settings Tab View
struct SettingsTabView: View {
    @State var path: NavigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            SettingView()
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
