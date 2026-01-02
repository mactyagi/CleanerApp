//
//  HomeView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI
import Contacts

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    init() {
        let deviceManager = DeviceInfoManager()
        _viewModel = StateObject(wrappedValue: HomeViewModel(deviceInfoManager: deviceManager, contactStore: CNContactStore()))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.lightBlueDarkGrey
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Storage Progress Section
                        storageSection

                        // Data Sync Progress (if syncing)
                        if viewModel.progress < 1 {
                            syncProgressSection
                        }

                        // Device Info Section
                        deviceInfoSection

                        // Quick Access Cards
                        quickAccessSection

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Home")
            .onAppear {
                logEvent(Event.HomeScreen.loaded.rawValue, parameter: nil)
                viewModel.updateData()
                NotificationCenter.default.addObserver(
                    forName: Notification.Name.updateData,
                    object: nil,
                    queue: .main
                ) { _ in
                    viewModel.fetchPhotoAndvideosCountAndSize()
                }
            }
            .onDisappear {
                viewModel.stopUpdatingDeviceInfo()
            }
        }
    }

    // MARK: - Storage Section

    private var storageSection: some View {
        VStack(spacing: 12) {
            // Circular Progress
            StorageProgressView(
                usedStorage: viewModel.usedStorage,
                totalStorage: viewModel.totalStorage
            )
            .frame(width: 150, height: 150)

            // Storage Labels
            VStack(spacing: 4) {
                Text(viewModel.usedStorage.formatBytes())
                    .font(.title2)
                    .fontWeight(.bold)

                Text("of \(viewModel.totalStorage.formatBytesWithRoundOff())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(uiColor: .primaryCell))
        .cornerRadius(20)
    }

    // MARK: - Sync Progress Section

    private var syncProgressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Analyzing photos...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(viewModel.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: Double(viewModel.progress))
                .tint(.blue)
        }
        .padding()
        .background(Color(uiColor: .primaryCell))
        .cornerRadius(15)
    }

    // MARK: - Device Info Section

    private var deviceInfoSection: some View {
        HStack(spacing: 12) {
            // RAM
            DeviceInfoCard(
                icon: "memorychip",
                title: "RAM",
                value: viewModel.availableRAM.formatBytes(),
                color: .indigo
            )

            // CPU
            DeviceInfoCard(
                icon: "cpu",
                title: "CPU",
                value: "Active",
                color: .purple
            )

            // WiFi
            DeviceInfoCard(
                icon: "wifi",
                title: "WiFi",
                value: "Connected",
                color: .teal
            )
        }
        .padding()
        .background(Color(uiColor: .primaryCell))
        .cornerRadius(15)
    }

    // MARK: - Quick Access Section

    private var quickAccessSection: some View {
        VStack(spacing: 12) {
            // Media Card
            NavigationLink(destination: MediaHubView()) {
                QuickAccessCard(
                    icon: "photo.fill",
                    iconColor: .green,
                    title: "Photos & Videos",
                    subtitle: viewModel.photosAndVideosSize != nil
                        ? "Items: \(viewModel.photosAndVideosCount) • \(viewModel.photosAndVideosSize?.formatBytes() ?? "")"
                        : "Give Access"
                )
            }

            // Calendar Card
            NavigationLink(destination: CalendarView()) {
                QuickAccessCard(
                    icon: "calendar",
                    iconColor: .pink,
                    title: "Calendar",
                    subtitle: eventsText
                )
            }

            // Contacts Card
            NavigationLink(destination: ContactsHubView()) {
                QuickAccessCard(
                    icon: "person.fill",
                    iconColor: .purple,
                    title: "Contacts",
                    subtitle: contactsText
                )
            }

            // Secret Space Card
            NavigationLink(destination: SecretSpaceView()) {
                QuickAccessCard(
                    icon: "lock.shield.fill",
                    iconColor: .indigo,
                    title: "Secret Space",
                    subtitle: "Private vault for photos"
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var eventsText: String {
        if let events = viewModel.eventsCount, let reminders = viewModel.reminderCount {
            return "Events: \(events + reminders)"
        }
        return "Give Access"
    }

    private var contactsText: String {
        if let count = viewModel.contactsCount {
            return "Contacts: \(count)"
        }
        return "Give Access"
    }
}

// MARK: - Storage Progress View

struct StorageProgressView: View {
    let usedStorage: Int64
    let totalStorage: Int64

    private var progress: Double {
        guard totalStorage > 0 else { return 0 }
        return Double(usedStorage) / Double(totalStorage)
    }

    private var percentage: Int {
        Int(min(progress * 100, 100))
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color(uiColor: .lightGray2))

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    Color.darkBlue,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Percentage text
            Text("\(percentage)%")
                .font(.system(size: 24, weight: .bold))
        }
        .padding(8)
    }
}

// MARK: - Device Info Card

struct DeviceInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Access Card

struct QuickAccessCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor)
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(uiColor: .primaryCell))
        .cornerRadius(15)
    }
}


#Preview {
    HomeView()
}
