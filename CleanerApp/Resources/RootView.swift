//
//  RootView.swift
//  CleanerApp
//
//  Root view that shows splash screen then transitions to MainTabView
//

import SwiftUI

struct RootView: View {
    @State private var showSplash = true
    @State private var iconScale: CGFloat = 0.1
    @State private var iconOpacity: Double = 0.0

    var body: some View {
        ZStack {
            MainTabView()
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                splashScreen
            }
        }
        .onAppear {
            startSplashAnimation()
        }
    }

    private var splashScreen: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            Image("AppsIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
        }
    }

    private func startSplashAnimation() {
        withAnimation(.easeOut(duration: 0.8)) {
            iconScale = 1.2
            iconOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.8)) {
                iconScale = 0.9
                iconOpacity = 0.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showSplash = false
            }
        }
    }
}
