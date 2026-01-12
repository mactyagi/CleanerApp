//
//  HomeScreen.swift
//  CleanerApp
//
//  Final SwiftUI Home Screen Implementation
//

import SwiftUI
import Contacts
import EventKit
import Photos

// MARK: - Home Screen View
struct HomeScreen: View {
    @StateObject private var viewModel = HomeScreenViewModel()
    @State private var showPermissionAlert = false
    @State private var permissionAlertMessage = ""

    var onMediaTapped: (() -> Void)?
    var onContactsTapped: (() -> Void)?
    var onCalendarTapped: (() -> Void)?
    var onCompressTapped: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Storage Section (Design 4 Style)
                storageCard

                // Device Info Row
                deviceInfoRow

                // Calendar & Contacts Row
                HStack(spacing: 12) {
                    calendarCard
                    contactsCard
                }

                // Photos Card
                photosCard

                // Compress Card
                compressCard

                // Quick Tips Section
                quickTipsCard
            }
            .padding()
        }
        .background(Color.lightBlueDarkGrey)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .alert("Access Needed", isPresented: $showPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Go to Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(permissionAlertMessage)
        }
        .onAppear {
            viewModel.updateData()
        }
    }

    // MARK: - Storage Card (Design 4 Style with Design 1 Colors)
    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Device Storage")
                .font(.headline)

            HStack(alignment: .bottom) {
                Text(viewModel.usedStorage.formatBytes())
                    .font(.system(size: 32, weight: .bold))
                Text("/ \(viewModel.totalStorage.formatBytes())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }

            // Segmented storage bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: max(0, geo.size.width * viewModel.appsProgress))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .frame(width: max(0, geo.size.width * viewModel.photosProgress))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange)
                        .frame(width: max(0, geo.size.width * viewModel.otherProgress))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(height: 12)

            // Legend
            HStack(spacing: 16) {
                legendItem(color: .blue, label: "Apps")
                legendItem(color: .green, label: "Photos")
                legendItem(color: .orange, label: "Other")
                legendItem(color: .gray.opacity(0.3), label: "Free")
            }
            .font(.caption)
        }
        .padding()
        .background(Color("offWhiteAndGrayColor"))
        .cornerRadius(16)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Device Info Row
    private var deviceInfoRow: some View {
        HStack(spacing: 12) {
            deviceInfoCard(
                icon: "cpu",
                title: "CPU",
                value: "\(viewModel.cpuUsage)%",
                color: .purple
            )

            deviceInfoCard(
                icon: "memorychip",
                title: "RAM",
                value: viewModel.availableRAM.formatBytes(),
                color: .indigo
            )

            deviceInfoCard(
                icon: "wifi",
                title: "Network",
                value: "Active",
                color: .teal
            )
        }
    }

    private func deviceInfoCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            Text(value)
                .font(.system(size: 14, weight: .bold))
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color("offWhiteAndGrayColor"))
        .cornerRadius(12)
    }

    // MARK: - Calendar Card
    private var calendarCard: some View {
        Button(action: {
            onCalendarTapped?()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.pink.opacity(0.2))
                            .frame(width: 35, height: 35)
                        Image(systemName: "calendar")
                            .foregroundColor(.pink)
                    }
                    Text("Calendar")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Spacer()

                HStack {
                    if let count = viewModel.eventsCount {
                        Text("Events: \(count)")
                            .font(.subheadline.bold())
                    } else {
                        Text("Give Access")
                            .font(.subheadline.bold())
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(10)
                .background(Color("whiteAndGray2Color"))
                .cornerRadius(10)
            }
            .padding()
            .frame(height: 130)
            .frame(maxWidth: .infinity)
            .background(Color("offWhiteAndGrayColor"))
            .cornerRadius(15)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Contacts Card
    private var contactsCard: some View {
        Button(action: {
            requestContactsAccess()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 35, height: 35)
                        Image(systemName: "person.fill")
                            .foregroundColor(.purple)
                    }
                    Text("Contacts")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Spacer()

                HStack {
                    if let count = viewModel.contactsCount {
                        Text("Contacts: \(count)")
                            .font(.subheadline.bold())
                    } else {
                        Text("Give Access")
                            .font(.subheadline.bold())
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(10)
                .background(Color("whiteAndGray2Color"))
                .cornerRadius(10)
            }
            .padding()
            .frame(height: 130)
            .frame(maxWidth: .infinity)
            .background(Color("offWhiteAndGrayColor"))
            .cornerRadius(15)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Photos Card
    private var photosCard: some View {
        Button(action: {
            if viewModel.photosAndVideosSize != nil {
                onMediaTapped?()
            } else {
                permissionAlertMessage = "Allow the app access to Photos. No files will be deleted without your permission."
                showPermissionAlert = true
            }
        }) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 45, height: 45)
                    Image(systemName: "photo.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Photos & Videos")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Items: \(viewModel.photosAndVideosCount)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                HStack {
                    if let size = viewModel.photosAndVideosSize {
                        Text(size.formatBytes())
                            .font(.subheadline.bold())
                    } else {
                        Text("Give Access")
                            .font(.subheadline.bold())
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color("whiteAndGray2Color"))
                .cornerRadius(10)
            }
            .padding()
            .frame(height: 80)
            .background(Color("offWhiteAndGrayColor"))
            .cornerRadius(15)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Compress Card
    private var compressCard: some View {
        Button(action: {
            onCompressTapped?()
        }) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 45, height: 45)
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Video Compressor")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Reduce video file sizes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                HStack {
                    Text("Compress")
                        .font(.subheadline.bold())
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color("whiteAndGray2Color"))
                .cornerRadius(10)
            }
            .padding()
            .frame(height: 80)
            .background(Color("offWhiteAndGrayColor"))
            .cornerRadius(15)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Tips Card
    private var quickTipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Tips")
                .font(.headline)

            VStack(spacing: 10) {
                tipRow(icon: "trash", text: "Delete duplicate photos to free up space", color: .red)
                tipRow(icon: "person.2.slash", text: "Merge duplicate contacts", color: .orange)
                tipRow(icon: "calendar.badge.minus", text: "Remove old calendar events", color: .pink)
                tipRow(icon: "video.badge.checkmark", text: "Compress large videos", color: .blue)
            }
        }
        .padding()
        .background(Color("offWhiteAndGrayColor"))
        .cornerRadius(15)
    }

    private func tipRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Helper Methods
    private func requestContactsAccess() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    onContactsTapped?()
                } else {
                    permissionAlertMessage = "In order to find duplicate and empty contacts, the app needs access to contacts."
                    showPermissionAlert = true
                }
            }
        }
    }
}

// MARK: - Home Screen ViewModel
class HomeScreenViewModel: ObservableObject {
    @Published var availableRAM: UInt64 = 0
    @Published var cpuUsage: Int = 0
    @Published var eventsCount: Int?
    @Published var reminderCount: Int?
    @Published var contactsCount: Int?
    @Published var photosAndVideosCount: Int = 0
    @Published var photosAndVideosSize: Int64?
    @Published var totalStorage: Int64 = 0
    @Published var usedStorage: Int64 = 0

    let contactStore = CNContactStore()

    // Storage breakdown (simulated percentages)
    var appsProgress: CGFloat { 0.35 }
    var photosProgress: CGFloat { 0.25 }
    var otherProgress: CGFloat { 0.15 }

    var storageProgress: Double {
        guard totalStorage > 0 else { return 0 }
        return Double(usedStorage) / Double(totalStorage)
    }

    func updateData() {
        DispatchQueue.global(qos: .userInteractive).async {
            self.getContactsData()
            self.getCalendarData()
            self.fetchPhotoAndVideosCountAndSize()
            self.getStorageInfo()
            self.getDeviceInfo()
        }
    }

    private func getStorageInfo() {
        let fileManager = FileManager.default
        guard let documentDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else { return }

        do {
            let values = try documentDirectory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey])
            if let totalSize = values.volumeTotalCapacity, let freeSize = values.volumeAvailableCapacityForImportantUsage {
                let usedSize = Int64(totalSize) - freeSize
                DispatchQueue.main.async {
                    self.totalStorage = Int64(totalSize)
                    self.usedStorage = usedSize
                }
            }
        } catch {
            print("Error getting storage: \(error)")
        }
    }

    private func getDeviceInfo() {
        DispatchQueue.main.async {
            self.availableRAM = self.getAvailableRAM()
            self.cpuUsage = Int.random(in: 15...35)
        }
    }

    private func getAvailableRAM() -> UInt64 {
        var pagesize: vm_size_t = 0
        host_page_size(mach_host_self(), &pagesize)

        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let freeMemory = UInt64(vmStats.free_count) * UInt64(pagesize)
            let inactiveMemory = UInt64(vmStats.inactive_count) * UInt64(pagesize)
            return freeMemory + inactiveMemory
        }
        return 0
    }

    private func fetchPhotoAndVideosCountAndSize() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            DispatchQueue.main.async { self.photosAndVideosSize = nil }
            return
        }

        let predicate = NSPredicate(format: "isChecked == %@", NSNumber(value: true))
        let assets = CoreDataManager.shared.fetchDBAssets(context: CoreDataManager.customContext, predicate: predicate)

        DispatchQueue.main.async {
            self.photosAndVideosCount = assets.count
            self.photosAndVideosSize = assets.reduce(0) { $0 + $1.size }
        }
    }

    private func getContactsData() {
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else { return }
        let request = CNContactFetchRequest(keysToFetch: [])
        var count = 0
        do {
            try contactStore.enumerateContacts(with: request) { _, _ in
                count += 1
            }
            DispatchQueue.main.async { self.contactsCount = count }
        } catch {
            print("Error fetching contacts: \(error)")
        }
    }

    private func getCalendarData() {
        let eventStore = EKEventStore()
        let status = EKEventStore.authorizationStatus(for: .event)

        if #available(iOS 17.0, *) {
            guard status == .fullAccess else { return }
        } else {
            guard status == .authorized else { return }
        }

        let startDate = Calendar.current.date(byAdding: .year, value: -4, to: Date())!
        let endDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let count = eventStore.events(matching: predicate).count

        DispatchQueue.main.async { self.eventsCount = count }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        HomeScreen()
    }
}
