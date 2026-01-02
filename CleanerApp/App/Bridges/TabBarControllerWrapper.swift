//
//  TabBarControllerWrapper.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI
import UIKit

struct TabBarControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> TabBarController {
        // Create TabBarController programmatically instead of from storyboard
        let tabBarController = TabBarController()
        return tabBarController
    }

    func updateUIViewController(_ uiViewController: TabBarController, context: Context) {
        // No updates needed
    }
}

#Preview {
    TabBarControllerWrapper()
        .ignoresSafeArea()
}
