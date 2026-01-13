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
    @State private var homeNavPath = NavigationPath()
    @State private var settingsNavPath = NavigationPath()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeTabView(path: $homeNavPath)
                .tabItem {
                    Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            // Settings Tab
            SettingsTabView(path: $settingsNavPath)
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
    @Binding var path: NavigationPath
    
    var body: some View {
        NavigationStack(path: $path) {
            SettingView()
        }
    }
}

// MARK: - Main Tab View Hosting Controller
class MainTabViewHostingController: UIHostingController<MainTabView> {
    init() {
        super.init(rootView: MainTabView())
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
