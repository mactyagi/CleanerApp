//
//  LaunchView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI

struct LaunchView: View {
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    @State private var isAnimationComplete = false

    var onComplete: (() -> Void)?

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            Image("AppsIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Fade in and scale up
        withAnimation(.easeOut(duration: 0.8)) {
            scale = 1.2
            opacity = 1.0
        }

        // Scale down slightly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.4)) {
                scale = 1.0
            }
        }

        // Complete after 2 seconds total
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onComplete?()
            }
        }
    }
}

#Preview {
    LaunchView()
}
