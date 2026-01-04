//
//  SecretSpaceView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI

struct SecretSpaceView: View {
    var body: some View {
        ZStack {
            Color.lightBlueDarkGrey
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    headerView

                    // Secret Storage Section
                    VStack(spacing: 0) {
                        NavigationLink(destination: SecretAlbumView()) {
                            SecretSpaceRow(
                                icon: "photo.stack.fill",
                                iconColor: .teal,
                                title: "Secret Album",
                                subtitle: "Your private photos and videos"
                            )
                        }

                        Divider()
                            .padding(.leading, 60)

                        SecretSpaceRow(
                            icon: "person.crop.circle.fill",
                            iconColor: .yellow,
                            title: "Secret Contacts",
                            subtitle: "Your private contacts",
                            isDisabled: true
                        )
                    }
                    .background(Color(uiColor: .primaryCell))
                    .cornerRadius(16)

                    // Protection Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Protection")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)

                        SecretSpaceRow(
                            icon: "lock.shield.fill",
                            iconColor: .red,
                            title: "Set Passcode",
                            subtitle: "Enhance storage security",
                            isDisabled: true
                        )
                        .background(Color(uiColor: .primaryCell))
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Secret Space")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text("Your Private Vault")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Keep your sensitive content safe and secure")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .primaryCell))
        .cornerRadius(16)
    }
}

// MARK: - Secret Space Row

struct SecretSpaceRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var isDisabled: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(isDisabled ? 0.5 : 1.0))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isDisabled ? .secondary : .primary)

                    if isDisabled {
                        Text("Coming Soon")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray)
                            .cornerRadius(4)
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !isDisabled {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .contentShape(Rectangle())
        .opacity(isDisabled ? 0.7 : 1.0)
    }
}

#Preview {
    NavigationStack {
        SecretSpaceView()
    }
}
