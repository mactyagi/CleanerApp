//
//  StorageDetailView.swift
//  CleanerApp
//
//  Storage Detail Screen — 5 switchable designs
//

import SwiftUI

// MARK: - Storage Tab Enum
enum StorageTab: String, CaseIterable, Identifiable {
    case breakdown = "Breakdown"
    case cleanup = "Cleanup"
    case trends = "Trends"
    case actions = "Actions"
    case system = "System"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .breakdown: return "chart.pie"
        case .cleanup: return "sparkles"
        case .trends: return "chart.line.uptrend.xyaxis"
        case .actions: return "bolt.fill"
        case .system: return "info.circle"
        }
    }
}

// MARK: - Storage Detail ViewModel
class StorageDetailViewModel: ObservableObject {
    @Published var selectedTab: StorageTab = .breakdown
    @Published var isClearingCache: Bool = false
    @Published var cacheCleared: Bool = false

    // System info
    @Published var deviceModel: String = ""
    @Published var iOSVersion: String = ""
    @Published var uptime: TimeInterval = 0

    // Storage breakdown
    @Published var systemStorage: Int64 = 0
    @Published var freeStorage: Int64 = 0

    func loadData(totalStorage: Int64, usedStorage: Int64) {
        iOSVersion = UIDevice.current.systemVersion
        deviceModel = getDeviceModelName()
        uptime = ProcessInfo.processInfo.systemUptime

        // Estimate system storage from the gap between total capacity and important usage capacity
        loadSystemStorage(totalStorage: totalStorage)
    }

    private func loadSystemStorage(totalStorage: Int64) {
        let fileManager = FileManager.default
        guard let docDir = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else { return }
        do {
            let values = try docDir.resourceValues(forKeys: [
                .volumeAvailableCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ])
            if let rawFree = values.volumeAvailableCapacity,
               let importantFree = values.volumeAvailableCapacityForImportantUsage {
                // System purgeable ≈ importantFree - rawFree
                let purgeable = max(0, importantFree - Int64(rawFree))
                systemStorage = purgeable
                freeStorage = Int64(rawFree)
            }
        } catch {}
    }

    func clearAppCaches() {
        isClearingCache = true
        DispatchQueue.global(qos: .userInitiated).async {
            URLCache.shared.removeAllCachedResponses()
            URLCache.shared.diskCapacity = 0
            URLCache.shared.memoryCapacity = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                URLCache.shared.memoryCapacity = 4 * 1024 * 1024
                URLCache.shared.diskCapacity = 20 * 1024 * 1024
            }
            Thread.sleep(forTimeInterval: 1.0)
            DispatchQueue.main.async {
                self.isClearingCache = false
                self.cacheCleared = true
            }
        }
    }

    private func getDeviceModelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { id, element in
            guard let value = element.value as? Int8, value != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(value)))
        }
        let map: [String: String] = [
            "iPhone17,1": "iPhone 16 Pro", "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16", "iPhone17,4": "iPhone 16 Plus",
            "iPhone16,1": "iPhone 15 Pro", "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone15,4": "iPhone 15", "iPhone15,5": "iPhone 15 Plus",
            "iPhone15,2": "iPhone 14 Pro", "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone14,7": "iPhone 14", "iPhone14,8": "iPhone 14 Plus",
            "iPhone14,2": "iPhone 13 Pro", "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,5": "iPhone 13", "iPhone14,4": "iPhone 13 mini",
            "x86_64": "Simulator", "arm64": "Simulator"
        ]
        return map[identifier] ?? identifier
    }

    var formattedUptime: String {
        let totalSeconds = Int(uptime)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        if days > 0 { return "\(days)d \(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

// MARK: - Storage Detail View
struct StorageDetailView: View {
    @StateObject private var viewModel = StorageDetailViewModel()
    @ObservedObject var homeViewModel: HomeScreenViewModel
    @Binding var path: NavigationPath

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Tab Switcher
                tabSwitcher
                    .padding(.horizontal)

                // Tab Content
                Group {
                    switch viewModel.selectedTab {
                    case .breakdown: breakdownTab
                    case .cleanup: cleanupTab
                    case .trends: trendsTab
                    case .actions: actionsTab
                    case .system: systemTab
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color("lightBlueDarkGreyColor"))
        .navigationTitle("Storage")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadData(totalStorage: homeViewModel.totalStorage, usedStorage: homeViewModel.usedStorage)
        }
    }

    // MARK: - Tab Switcher
    private var tabSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StorageTab.allCases) { tab in
                    let isSelected = viewModel.selectedTab == tab
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(tab.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.blue : Color("offWhiteAndGrayColor"))
                                .shadow(color: .black.opacity(isSelected ? 0.15 : 0.04), radius: 4, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Reusable
    private func infoCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .padding()
            .background(Color("offWhiteAndGrayColor"))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func infoRow(icon: String, label: String, value: String, iconColor: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(iconColor.opacity(0.15)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(iconColor)
            }
            Text(label).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline.bold()).multilineTextAlignment(.trailing)
        }
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

    // MARK: ─── Tab 1: Breakdown ───
    private var breakdownTab: some View {
        let total = max(homeViewModel.totalStorage, 1)
        let free = total - homeViewModel.usedStorage
        let photosSize = homeViewModel.photosAndVideosSize ?? 0
        let systemSize = viewModel.systemStorage
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

    // MARK: ─── Tab 2: Cleanup ───
    private var cleanupTab: some View {
        VStack(spacing: 16) {
            // Summary
            if let photosSize = homeViewModel.photosAndVideosSize, photosSize > 0 {
                infoCard {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.orange.opacity(0.15)).frame(width: 44, height: 44)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 20)).foregroundColor(.orange)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(homeViewModel.photosAndVideosCount) items to review")
                                .font(.subheadline.bold())
                            Text("\(photosSize.formatBytes()) can be cleaned")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }

            // Recommendations
            infoCard {
                cleanupRow(icon: "photo.on.rectangle", label: "Clean Duplicate Photos",
                           subtitle: "Find and remove duplicates", color: .green) {
                    path.append(HomeDestination.media)
                }
                cardDivider()
                cleanupRow(icon: "calendar.badge.minus", label: "Remove Old Events",
                           subtitle: "\(homeViewModel.eventsCount ?? 0) past events", color: .pink) {
                    path.append(HomeDestination.calendar)
                }
                cardDivider()
                cleanupRow(icon: "person.2.fill", label: "Merge Duplicate Contacts",
                           subtitle: "\(homeViewModel.contactsCount ?? 0) total contacts", color: .indigo) {
                    path.append(HomeDestination.contacts)
                }
                cardDivider()
                cleanupRow(icon: "video.fill", label: "Compress Large Videos",
                           subtitle: "Reduce video file sizes", color: .blue) {
                    path.append(HomeDestination.compress)
                }
            }

            // Clear Cache button
            Button {
                viewModel.clearAppCaches()
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isClearingCache {
                        ProgressView().tint(.white).scaleEffect(0.9)
                    } else {
                        Image(systemName: viewModel.cacheCleared ? "checkmark" : "trash.fill")
                    }
                    Text(viewModel.isClearingCache ? "Clearing..." : (viewModel.cacheCleared ? "Cache Cleared" : "Clear App Caches"))
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(viewModel.cacheCleared ? Color.green : Color.red)
                        .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isClearingCache || viewModel.cacheCleared)
            .opacity(viewModel.isClearingCache ? 0.7 : 1)
        }
    }

    private func cleanupRow(icon: String, label: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 34, height: 34)
                    Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.subheadline).foregroundColor(.primary)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: ─── Tab 3: Trends ───
    private var trendsTab: some View {
        let cleanable = homeViewModel.photosAndVideosSize ?? 0
        let total = max(homeViewModel.totalStorage, 1)
        let used = homeViewModel.usedStorage
        let free = total - used

        return VStack(spacing: 16) {
            // Cleanable summary
            infoCard {
                VStack(spacing: 14) {
                    HStack {
                        Text("Storage Overview")
                            .font(.headline)
                        Spacer()
                    }

                    // Stacked bar: Used | Cleanable | Free
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(width: geo.size.width * CGFloat(Double(used - cleanable) / Double(total)))
                            if cleanable > 0 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.orange)
                                    .frame(width: geo.size.width * CGFloat(Double(cleanable) / Double(total)))
                            }
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green.opacity(0.4))
                        }
                    }
                    .frame(height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                    HStack(spacing: 12) {
                        legendItem(color: .blue, label: "Used")
                        if cleanable > 0 { legendItem(color: .orange, label: "Cleanable") }
                        legendItem(color: .green.opacity(0.4), label: "Free")
                        Spacer()
                    }
                }
            }

            // Stats
            infoCard {
                infoRow(icon: "internaldrive.fill", label: "Total Capacity",
                        value: homeViewModel.totalStorage.formatBytes(), iconColor: .blue)
                cardDivider()
                infoRow(icon: "chart.bar.fill", label: "Currently Used",
                        value: used.formatBytes(), iconColor: .red)
                cardDivider()
                infoRow(icon: "externaldrive.fill", label: "Free Space",
                        value: free.formatBytes(), iconColor: .green)
                cardDivider()
                infoRow(icon: "sparkles", label: "Ready to Clean",
                        value: cleanable.formatBytes(), iconColor: .orange)
            }

            // Items scanned
            infoCard {
                infoRow(icon: "photo.stack", label: "Media Scanned",
                        value: "\(homeViewModel.photosAndVideosCount) items", iconColor: .green)
                cardDivider()
                infoRow(icon: "person.2", label: "Contacts",
                        value: "\(homeViewModel.contactsCount ?? 0)", iconColor: .indigo)
                cardDivider()
                infoRow(icon: "calendar", label: "Past Events",
                        value: "\(homeViewModel.eventsCount ?? 0)", iconColor: .pink)
            }
        }
    }

    // MARK: ─── Tab 4: Quick Actions ───
    private var actionsTab: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                actionCard(icon: "photo.fill", title: "Clean Photos",
                           count: "\(homeViewModel.photosAndVideosCount) items",
                           color: .green) {
                    path.append(HomeDestination.media)
                }
                actionCard(icon: "person.2.fill", title: "Clean Contacts",
                           count: "\(homeViewModel.contactsCount ?? 0) contacts",
                           color: .indigo) {
                    path.append(HomeDestination.contacts)
                }
            }
            HStack(spacing: 12) {
                actionCard(icon: "calendar", title: "Clean Calendar",
                           count: "\(homeViewModel.eventsCount ?? 0) events",
                           color: .pink) {
                    path.append(HomeDestination.calendar)
                }
                actionCard(icon: "video.fill", title: "Compress Videos",
                           count: "Reduce file sizes",
                           color: .blue) {
                    path.append(HomeDestination.compress)
                }
            }
            HStack(spacing: 12) {
                actionCard(icon: "cpu", title: "Device Health",
                           count: "CPU, RAM, Network",
                           color: .purple) {
                    path.append(HomeDestination.deviceHealth(.cpu))
                }
                actionCard(icon: "speedometer", title: "Speed Test",
                           count: "Test your network",
                           color: .teal) {
                    path.append(HomeDestination.speedTest)
                }
            }
        }
    }

    private func actionCard(icon: String, title: String, count: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 48, height: 48)
                    Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
                }
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                Text(count)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color("offWhiteAndGrayColor"))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: ─── Tab 5: System Info ───
    private var systemTab: some View {
        VStack(spacing: 16) {
            infoCard {
                infoRow(icon: "iphone", label: "Device", value: viewModel.deviceModel, iconColor: .blue)
                cardDivider()
                infoRow(icon: "gear", label: "iOS Version", value: viewModel.iOSVersion, iconColor: .blue)
                cardDivider()
                infoRow(icon: "clock.fill", label: "Uptime", value: viewModel.formattedUptime, iconColor: .blue)
            }

            infoCard {
                infoRow(icon: "internaldrive.fill", label: "Total Capacity",
                        value: homeViewModel.totalStorage.formatBytes(), iconColor: .purple)
                cardDivider()
                infoRow(icon: "chart.bar.fill", label: "Used Storage",
                        value: homeViewModel.usedStorage.formatBytes(), iconColor: .red)
                cardDivider()
                infoRow(icon: "externaldrive.fill", label: "Available",
                        value: (homeViewModel.totalStorage - homeViewModel.usedStorage).formatBytes(), iconColor: .green)
                cardDivider()
                infoRow(icon: "gear", label: "System Reserve",
                        value: viewModel.systemStorage.formatBytes(), iconColor: .purple)
            }

            infoCard {
                infoRow(icon: "memorychip", label: "Storage Type", value: "NVMe Flash", iconColor: .teal)
                cardDivider()
                infoRow(icon: "doc.fill", label: "File System", value: "APFS", iconColor: .teal)
                cardDivider()
                infoRow(icon: "lock.fill", label: "Encryption", value: "AES-256", iconColor: .teal)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        StorageDetailView(homeViewModel: HomeScreenViewModel(), path: .constant(NavigationPath()))
    }
}
