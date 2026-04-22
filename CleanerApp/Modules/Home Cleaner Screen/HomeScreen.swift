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

// MARK: - Home Tab View (Navigation Container)
struct HomeNavigationView: View {
    @State var path: NavigationPath = NavigationPath()
    @StateObject private var contactsViewModel = OrganizeContactViewModel(contactStore: CNContactStore())
    @StateObject private var mediaViewModel = MediaViewModel()
    @StateObject private var homeViewModel = HomeScreenViewModel()

    var body: some View {
        NavigationStack(path: $path) {
            HomeScreen(viewModel: homeViewModel, path: $path)
            .navigationDestination(for: HomeDestination.self) { destination in
                homeDestinationView(for: destination)
                    .toolbar(.hidden, for: .tabBar)
            }
            .navigationDestination(for: ContactsDestination.self) { destination in
                contactsDestinationView(for: destination)
                    .toolbar(.hidden, for: .tabBar)
            }
            .navigationDestination(for: MediaDestination.self) { destination in
                mediaDestinationView(for: destination)
                    .toolbar(.hidden, for: .tabBar)
                
            }
        }
    }
    
    @ViewBuilder
    private func homeDestinationView(for destination: HomeDestination) -> some View {
        switch destination {
        case .media:
            MediaFlowView(viewModel: mediaViewModel, path: $path)
        case .contacts:
            OrganizeContactsView(viewModel: contactsViewModel, path: $path)
        case .calendar:
            CalendarDesignSelector()
        case .compress:
            CompressorDetailView()
        case .deviceHealth(let tab):
            DeviceHealthView(initialTab: tab, homeViewModel: homeViewModel, path: $path)
        case .speedTest:
            SpeedTestView()
        case .storageDetail:
            StorageDetailView(homeViewModel: homeViewModel, path: $path)
        }

    }
    
    @ViewBuilder
    private func contactsDestinationView(for destination: ContactsDestination) -> some View {
        switch destination {
        case .duplicates:
            DuplicateContactsViewDesign(
                viewModel: DuplicateContactsViewModel(contactStore: CNContactStore())
            )
        case .incomplete:
            IncompleteContactView(
                viewModel: IncompleteContactViewModel(contactStore: CNContactStore())
            )
        case .allContacts:
            AllContactsView(
                viewModel: AllContactsVIewModel(contactStore: CNContactStore())
            )
        case .backup:
            ContactsBackupView(contacts: contactsViewModel.allContacts)
        }
    }
    
    @ViewBuilder
    private func mediaDestinationView(for destination: MediaDestination) -> some View {
        switch destination {
        case .baseView(let cellType):
            if let predicate = mediaViewModel.getPredicate(mediaType: cellType) {
                BaseViewSwiftUI(
                    predicate: predicate,
                    groupType: cellType.groupType,
                    type: cellType
                )
            } else {
                Text("No data available")
            }
        case .otherPhotos(let cellType):
            OtherPhotosSwiftUI(
                predicate: mediaViewModel.getPredicate(mediaType: cellType),
                cellType: cellType
            )
        }
    }
}

// MARK: - Device Health Tab
enum DeviceHealthTab: String, CaseIterable, Hashable {
    case cpu = "CPU"
    case ram = "RAM"
    case network = "Network"

    var icon: String {
        switch self {
        case .cpu: return "cpu"
        case .ram: return "memorychip"
        case .network: return "wifi"
        }
    }

    var color: Color {
        switch self {
        case .cpu: return .purple
        case .ram: return .indigo
        case .network: return .teal
        }
    }
}

// MARK: - Home Destinations
enum HomeDestination: Hashable {
    case media
    case contacts
    case calendar
    case compress
    case deviceHealth(DeviceHealthTab)
    case speedTest
    case storageDetail
}

// MARK: - Home Screen View
struct HomeScreen: View {
    @ObservedObject var viewModel: HomeScreenViewModel
    @Binding var path: NavigationPath
    @State private var showPermissionAlert = false
    @State private var permissionAlertMessage = ""
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Storage Section (Design 4 Style)
                Button {
                    path.append(HomeDestination.storageDetail)
                } label: {
                    storageCard
                }
                .buttonStyle(.plain)

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
            viewModel.startDeviceInfoTimer()
        }
        .onDisappear {
            viewModel.stopDeviceInfoTimer()
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
            Button {
                path.append(HomeDestination.deviceHealth(.cpu))
            } label: {
                deviceInfoCard(
                    icon: "cpu",
                    title: "CPU",
                    value: "\(viewModel.cpuUsage)%",
                    color: .purple
                )
            }
            .buttonStyle(.plain)

            Button {
                path.append(HomeDestination.deviceHealth(.ram))
            } label: {
                deviceInfoCard(
                    icon: "memorychip",
                    title: "RAM",
                    value: viewModel.usedRAM.formatBytes(),
                    color: .indigo
                )
            }
            .buttonStyle(.plain)

            Button {
                path.append(HomeDestination.deviceHealth(.network))
            } label: {
                deviceInfoCard(
                    icon: "wifi",
                    title: "Network",
                    value: "Active",
                    color: .teal
                )
            }
            .buttonStyle(.plain)
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
            path.append(HomeDestination.calendar)
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
                path.append(HomeDestination.media)
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
            path.append(HomeDestination.compress)
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
                    path.append(HomeDestination.contacts)
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
    @Published var cpuUser: Double = 0
    @Published var cpuSystem: Double = 0
    @Published var cpuIdle: Double = 0
    @Published var totalRAM: UInt64 = 0
    @Published var usedRAM: UInt64 = 0
    @Published var wiredMemory: UInt64 = 0
    @Published var activeMemory: UInt64 = 0
    @Published var inactiveMemory: UInt64 = 0
    @Published var freeMemory: UInt64 = 0
    @Published var appMemoryFootprint: UInt64 = 0
    @Published var eventsCount: Int?
    @Published var reminderCount: Int?
    @Published var contactsCount: Int?
    @Published var photosAndVideosCount: Int = 0
    @Published var photosAndVideosSize: Int64?
    @Published var totalStorage: Int64 = 0
    @Published var usedStorage: Int64 = 0

    let contactStore = CNContactStore()
    private var deviceInfoTimer: Timer?

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

    func startDeviceInfoTimer() {
        deviceInfoTimer?.invalidate()
        deviceInfoTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            DispatchQueue.global(qos: .userInteractive).async {
                self?.getDeviceInfo()
            }
        }
    }

    func stopDeviceInfoTimer() {
        deviceInfoTimer?.invalidate()
        deviceInfoTimer = nil
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
        let cpu = getCPUBreakdown()
        let ram = getRAMBreakdown()
        let footprint = getAppMemoryFootprint()

        DispatchQueue.main.async {
            self.cpuUsage = cpu.total
            self.cpuUser = cpu.user
            self.cpuSystem = cpu.system
            self.cpuIdle = cpu.idle

            self.totalRAM = ProcessInfo.processInfo.physicalMemory
            self.wiredMemory = ram.wired
            self.activeMemory = ram.active
            self.inactiveMemory = ram.inactive
            self.freeMemory = ram.free
            self.availableRAM = ram.free + ram.inactive
            self.usedRAM = self.totalRAM - self.availableRAM
            self.appMemoryFootprint = footprint
        }
    }

    private func getRAMBreakdown() -> (wired: UInt64, active: UInt64, inactive: UInt64, free: UInt64) {
        var pagesize: vm_size_t = 0
        host_page_size(mach_host_self(), &pagesize)

        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return (0, 0, 0, 0) }
        let ps = UInt64(pagesize)
        return (
            wired: UInt64(vmStats.wire_count) * ps,
            active: UInt64(vmStats.active_count) * ps,
            inactive: UInt64(vmStats.inactive_count) * ps,
            free: UInt64(vmStats.free_count) * ps
        )
    }

    private func getAppMemoryFootprint() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? UInt64(info.phys_footprint) : 0
    }

    private func getCPUBreakdown() -> (total: Int, user: Double, system: Double, idle: Double) {
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0

        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &numCPUInfo)
        guard result == KERN_SUCCESS, let info = cpuInfo else { return (0, 0, 0, 100) }

        var totalUser: Double = 0
        var totalSystem: Double = 0
        var totalIdle: Double = 0
        var totalNice: Double = 0

        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            totalUser += Double(info[offset + Int(CPU_STATE_USER)])
            totalSystem += Double(info[offset + Int(CPU_STATE_SYSTEM)])
            totalIdle += Double(info[offset + Int(CPU_STATE_IDLE)])
            totalNice += Double(info[offset + Int(CPU_STATE_NICE)])
        }

        let total = totalUser + totalSystem + totalIdle + totalNice
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(numCPUInfo) * vm_size_t(MemoryLayout<integer_t>.size))

        guard total > 0 else { return (0, 0, 0, 100) }
        let userPct = (totalUser / total) * 100
        let systemPct = (totalSystem / total) * 100
        let idlePct = (totalIdle / total) * 100
        return (min(Int(userPct + systemPct), 100), userPct, systemPct, idlePct)
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
        HomeScreen(viewModel: HomeScreenViewModel(), path: .constant(NavigationPath()))
    }
}
