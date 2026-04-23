//
//  test.swift
//  CleanerApp
//
//  Created by Manukant Harshmani Tyagi on 23/04/26.
//

import SwiftUI
import Photos

struct MediaEmptyStateView: View {
    let mediaType: MediaCellType
    let groupType: PHAssetGroupType

    @State private var animate = false
    @State private var showConfetti = false

    private var icon: String {
        switch groupType {
        case .duplicate: return "doc.on.doc.fill"
        case .similar: return "photo.on.rectangle.angled"
        default: return "photo.stack.fill"
        }
    }

    private var title: String {
        switch groupType {
        case .duplicate: return "No Duplicates Found"
        case .similar: return "No Similar Items Found"
        default: return "All Clean!"
        }
    }

    private var subtitle: String {
        switch groupType {
        case .duplicate: return "Your library has no duplicate files.\nEverything is unique!"
        case .similar: return "No similar-looking items detected.\nYour collection is well-curated!"
        default: return "Nothing to clean up here.\nYour library is in great shape!"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                // Pulsing background rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(Color.green.opacity(0.08 - Double(index) * 0.02), lineWidth: 2)
                        .frame(
                            width: CGFloat(160 + index * 50),
                            height: CGFloat(160 + index * 50)
                        )
                        .scaleEffect(animate ? 1.05 : 0.95)
                        .animation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                            value: animate
                        )
                }

                // Main icon circle
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.2), Color.green.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 130, height: 130)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                        .shadow(color: Color.green.opacity(0.4), radius: 16, x: 0, y: 8)

                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(animate ? 1.0 : 0.5)
                .opacity(animate ? 1.0 : 0.0)

                // Floating sparkles
                ForEach(0..<6, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: CGFloat.random(in: 10...18)))
                        .foregroundColor(sparkleColor(for: index))
                        .offset(sparkleOffset(for: index))
                        .opacity(showConfetti ? 1 : 0)
                        .scaleEffect(showConfetti ? 1 : 0.3)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.5)
                            .delay(0.4 + Double(index) * 0.08),
                            value: showConfetti
                        )
                }
            }

            Spacer().frame(height: 40)

            // Title
            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 20)

            Spacer().frame(height: 12)

            // Subtitle
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 20)

            Spacer().frame(height: 32)

            // Category pill
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(mediaType.rawValue)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(.green)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.green.opacity(0.1))
            )
            .opacity(animate ? 1 : 0)
            .scaleEffect(animate ? 1 : 0.8)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animate = true
            }
            showConfetti = true
        }
    }

    private func sparkleColor(for index: Int) -> Color {
        let colors: [Color] = [.green, .yellow, .blue, .green, .orange, .mint]
        return colors[index % colors.count]
    }

    private func sparkleOffset(for index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / 6.0) * .pi / 180
        let radius: CGFloat = 85
        return CGSize(
            width: cos(angle) * radius,
            height: sin(angle) * radius
        )
    }
}
