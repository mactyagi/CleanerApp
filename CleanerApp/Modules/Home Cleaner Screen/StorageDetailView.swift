//
//  StorageDetailView.swift
//  CleanerApp
//
//  Storage Detail Screen — Breakdown only
//

import SwiftUI

// MARK: - Storage Detail View
struct StorageDetailView: View {
    @ObservedObject var homeViewModel: HomeScreenViewModel
    @Binding var path: NavigationPath

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                breakdownContent
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color("lightBlueDarkGreyColor"))
        .navigationTitle("Storage")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Reusable
    private func infoCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .padding()
            .background(Color("offWhiteAndGrayColor"))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func cardDivider() -> some View {
        Divider().padding(.leading, 46)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
    }

    // MARK: ─── Breakdown ───
    private var breakdownContent: some View {
        let total = max(homeViewModel.totalStorage, 1)
        let free = total - homeViewModel.usedStorage
        let photosSize = homeViewModel.photosAndVideosSize ?? 0
        let systemSize = homeViewModel.systemStorage
        let appsSize = max(0, homeViewModel.usedStorage - photosSize - systemSize)

        return VStack(spacing: 16) {
            // Storage bar
            infoCard {
                VStack(spacing: 14) {
                    HStack(alignment: .bottom) {
                        Text(homeViewModel.usedStorage.formatBytes())
                            .font(.system(size: 28, weight: .bold))
                        Text("/ \(homeViewModel.totalStorage.formatBytes())")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 2)
                        Spacer()
                    }

                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(width: max(0, geo.size.width * CGFloat(Double(appsSize) / Double(total))))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green)
                                .frame(width: max(0, geo.size.width * CGFloat(Double(photosSize) / Double(total))))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.orange)
                                .frame(width: max(0, geo.size.width * CGFloat(Double(systemSize) / Double(total))))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                    .frame(height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                    HStack(spacing: 12) {
                        legendItem(color: .blue, label: "Apps")
                        legendItem(color: .green, label: "Media")
                        legendItem(color: .orange, label: "Other")
                        legendItem(color: .gray.opacity(0.3), label: "Free")
                        Spacer()
                    }
                }
            }

            // Category rows
            infoCard {
                storageRow(icon: "square.grid.2x2.fill", label: "Apps & Data", size: appsSize, total: total, color: .blue)
                cardDivider()
                storageRow(icon: "photo.fill", label: "Photos & Videos", size: photosSize, total: total, color: .green)
                cardDivider()
                storageRow(icon: "gear", label: "Other", size: systemSize, total: total, color: .orange)
                cardDivider()
                storageRow(icon: "externaldrive.fill", label: "Free Space", size: free, total: total, color: .gray)
            }

            // Tips & Hidden Features
            VStack(alignment: .leading, spacing: 12) {
                Text("Tips & Hidden Features")
                    .font(.headline)
                    .padding(.top, 4)

                tipCard(icon: "photo.on.rectangle.angled",
                        title: "Swipe to Clean Photos",
                        description: "Open Photos cleaner and swipe left on any photo to quickly mark it for deletion — like Tinder for your gallery.",
                        color: .green)

                tipCard(icon: "video.badge.checkmark",
                        title: "Compress Without Losing Quality",
                        description: "Use the Video Compressor with 'Optimal' mode to reduce file size by 40% while keeping visual quality nearly identical.",
                        color: .blue)

                tipCard(icon: "person.2.badge.gearshape",
                        title: "Merge Duplicate Contacts",
                        description: "The Contacts cleaner finds duplicates automatically. Tap 'Merge All' to combine them in one tap.",
                        color: .indigo)

                tipCard(icon: "calendar.badge.clock",
                        title: "Clean Old Calendar Events",
                        description: "Past events from up to 4 years ago can pile up. The Calendar cleaner lets you bulk-delete them by year.",
                        color: .pink)

                tipCard(icon: "bolt.circle",
                        title: "Boost RAM Instantly",
                        description: "Go to Device Health → RAM tab and tap 'Boost Memory' to clear URL and image caches and free up RAM.",
                        color: .purple)

                tipCard(icon: "speedometer",
                        title: "Built-in Speed Test",
                        description: "Check your real download and upload speed from Network tab → Speed Test. It runs until speed stabilizes for accurate results.",
                        color: .teal)

                tipCard(icon: "trash.circle",
                        title: "Clear App Caches",
                        description: "Go to Storage → Cleanup tab and tap 'Clear App Caches' to remove cached data and free some space.",
                        color: .red)

                tipCard(icon: "iphone.radiowaves.left.and.right",
                        title: "Check VPN & Network Details",
                        description: "The Network tab in Device Health shows your IP address, WiFi name, and whether a VPN is active — useful for debugging connections.",
                        color: .orange)
            }
        }
    }

    private func storageRow(icon: String, label: String, size: Int64, total: Int64, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 34, height: 34)
                    Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
                }
                Text(label).font(.subheadline)
                Spacer()
                Text(size.formatBytes()).font(.subheadline.bold())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(color.opacity(0.1))
                    RoundedRectangle(cornerRadius: 3).fill(color)
                        .frame(width: geo.size.width * CGFloat(Double(size) / Double(max(total, 1))))
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
    }

    private func tipCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)).frame(width: 38, height: 38)
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("offWhiteAndGrayColor"))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        StorageDetailView(homeViewModel: HomeScreenViewModel(), path: .constant(NavigationPath()))
    }
}
