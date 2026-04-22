//
//  DeviceHealthView.swift
//  CleanerApp
//
//  Device Health Detail Screen — CPU, RAM, Network tabs
//

import SwiftUI
import Network
import CoreTelephony

// MARK: - Device Health ViewModel
class DeviceHealthViewModel: ObservableObject {
    @Published var selectedTab: DeviceHealthTab

    // MARK: CPU / Device Info
    @Published var deviceModel: String = ""
    @Published var iOSVersion: String = ""
    @Published var processorInfo: String = ""
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
    @Published var batteryLevel: Float = -1
    @Published var batteryState: UIDevice.BatteryState = .unknown
    @Published var isLowPowerMode: Bool = false
    @Published var uptime: TimeInterval = 0

    // MARK: RAM (boost only)
    @Published var isBoostingMemory: Bool = false

    // MARK: Network
    @Published var connectionType: String = "Checking..."
    @Published var wifiSSID: String = "N/A"
    @Published var carrierName: String = "N/A"
    @Published var ipAddress: String = "N/A"
    @Published var isVPNActive: Bool = false
    @Published var interfaceType: String = "N/A"
    @Published var dataSent: UInt64 = 0
    @Published var dataReceived: UInt64 = 0

    private var monitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "com.cleanerapp.networkmonitor")

    init(initialTab: DeviceHealthTab) {
        self.selectedTab = initialTab
    }

    deinit {
        monitor?.cancel()
        UIDevice.current.isBatteryMonitoringEnabled = false
    }

    // MARK: - Load All Data
    func loadAllData() {
        loadDeviceInfo()
        loadNetworkData()
    }

    // MARK: - Device Info (static data only — CPU/RAM come from HomeScreenViewModel)
    func loadDeviceInfo() {
        DispatchQueue.main.async {
            self.deviceModel = self.getDeviceModelName()
            self.iOSVersion = UIDevice.current.systemVersion
            self.processorInfo = self.getProcessorInfo()
            self.thermalState = ProcessInfo.processInfo.thermalState
            self.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
            self.uptime = ProcessInfo.processInfo.systemUptime

            UIDevice.current.isBatteryMonitoringEnabled = true
            self.batteryLevel = UIDevice.current.batteryLevel
            self.batteryState = UIDevice.current.batteryState
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
        return mapToDeviceName(identifier: identifier)
    }

    private func mapToDeviceName(identifier: String) -> String {
        let deviceMap: [String: String] = [
            // iPhone 16 series
            "iPhone17,1": "iPhone 16 Pro", "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16", "iPhone17,4": "iPhone 16 Plus",
            // iPhone 15 series
            "iPhone16,1": "iPhone 15 Pro", "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone15,4": "iPhone 15", "iPhone15,5": "iPhone 15 Plus",
            // iPhone 14 series
            "iPhone15,2": "iPhone 14 Pro", "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone14,7": "iPhone 14", "iPhone14,8": "iPhone 14 Plus",
            // iPhone 13 series
            "iPhone14,2": "iPhone 13 Pro", "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,5": "iPhone 13", "iPhone14,4": "iPhone 13 mini",
            // iPhone 12 series
            "iPhone13,3": "iPhone 12 Pro", "iPhone13,4": "iPhone 12 Pro Max",
            "iPhone13,2": "iPhone 12", "iPhone13,1": "iPhone 12 mini",
            // iPhone 11 series
            "iPhone12,3": "iPhone 11 Pro", "iPhone12,5": "iPhone 11 Pro Max",
            "iPhone12,1": "iPhone 11",
            // iPhone SE
            "iPhone14,6": "iPhone SE (3rd gen)", "iPhone12,8": "iPhone SE (2nd gen)",
            // iPad common
            "iPad13,18": "iPad (10th gen)", "iPad13,19": "iPad (10th gen)",
            "iPad14,3": "iPad Pro 11\" (4th gen)", "iPad14,4": "iPad Pro 11\" (4th gen)",
            "iPad14,5": "iPad Pro 12.9\" (6th gen)", "iPad14,6": "iPad Pro 12.9\" (6th gen)",
            // Simulator
            "x86_64": "Simulator", "arm64": "Simulator"
        ]
        return deviceMap[identifier] ?? identifier
    }

    private func getProcessorInfo() -> String {
        var size: size_t = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        let identifier = String(cString: machine)

        let chipMap: [String: String] = [
            "iPhone17": "A18 Pro", "iPhone16": "A17 Pro", "iPhone15": "A16 / A15",
            "iPhone14": "A15 Bionic", "iPhone13": "A14 Bionic", "iPhone12": "A13 Bionic",
            "iPad14": "M2", "iPad13": "A14 Bionic",
        ]

        let prefix = identifier.components(separatedBy: ",").first ?? identifier
        for (key, chip) in chipMap {
            if prefix.hasPrefix(key) { return chip }
        }
        return "Apple Silicon"
    }

    func boostMemory() {
        isBoostingMemory = true
        DispatchQueue.global(qos: .userInitiated).async {
            URLCache.shared.removeAllCachedResponses()
            URLCache.shared.diskCapacity = 0
            URLCache.shared.memoryCapacity = 0

            // Reset to defaults after clearing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                URLCache.shared.memoryCapacity = 4 * 1024 * 1024
                URLCache.shared.diskCapacity = 20 * 1024 * 1024
            }

            Thread.sleep(forTimeInterval: 1.0)

            DispatchQueue.main.async {
                self.isBoostingMemory = false
            }
        }
    }

    // MARK: - Network Data
    func loadNetworkData() {
        startNetworkMonitor()
        loadCarrierInfo()
        loadIPAddress()
        loadVPNStatus()
        loadNetworkDataCounters()
    }

    private func startNetworkMonitor() {
        monitor?.cancel()
        let newMonitor = NWPathMonitor()
        monitor = newMonitor

        newMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) {
                        self?.connectionType = "WiFi"
                        self?.interfaceType = "WiFi (en0)"
                    } else if path.usesInterfaceType(.cellular) {
                        self?.connectionType = "Cellular"
                        self?.interfaceType = "Cellular (pdp_ip0)"
                    } else if path.usesInterfaceType(.wiredEthernet) {
                        self?.connectionType = "Ethernet"
                        self?.interfaceType = "Wired Ethernet"
                    } else {
                        self?.connectionType = "Connected"
                        self?.interfaceType = "Other"
                    }
                } else {
                    self?.connectionType = "No Connection"
                    self?.interfaceType = "None"
                }
            }
        }
        newMonitor.start(queue: monitorQueue)
    }

    private func loadCarrierInfo() {
        let networkInfo = CTTelephonyNetworkInfo()
        if let carriers = networkInfo.serviceSubscriberCellularProviders {
            let names = carriers.values.compactMap { $0.carrierName }
            DispatchQueue.main.async {
                self.carrierName = names.first ?? "N/A"
            }
        }
    }

    private func loadIPAddress() {
        var address = "N/A"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "pdp_ip0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                    address = String(cString: hostname)
                    if name == "en0" { break }
                }
            }
        }

        DispatchQueue.main.async { self.ipAddress = address }
    }

    private func loadVPNStatus() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }

        var vpnDetected = false
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let name = String(cString: ptr.pointee.ifa_name)
            if name.hasPrefix("utun") || name.hasPrefix("ipsec") || name.hasPrefix("ppp") {
                vpnDetected = true
                break
            }
        }
        DispatchQueue.main.async { self.isVPNActive = vpnDetected }
    }

    private func loadNetworkDataCounters() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }

        var totalSent: UInt64 = 0
        var totalReceived: UInt64 = 0

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            if interface.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "pdp_ip0" {
                    if let data = interface.ifa_data {
                        let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                        totalSent += UInt64(networkData.ifi_obytes)
                        totalReceived += UInt64(networkData.ifi_ibytes)
                    }
                }
            }
        }

        DispatchQueue.main.async {
            self.dataSent = totalSent
            self.dataReceived = totalReceived
        }
    }

}

// MARK: - Device Health View
struct DeviceHealthView: View {
    @StateObject private var viewModel: DeviceHealthViewModel
    @ObservedObject var homeViewModel: HomeScreenViewModel
    @Binding var path: NavigationPath

    init(initialTab: DeviceHealthTab, homeViewModel: HomeScreenViewModel, path: Binding<NavigationPath>) {
        _viewModel = StateObject(wrappedValue: DeviceHealthViewModel(initialTab: initialTab))
        self.homeViewModel = homeViewModel
        self._path = path
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                tabSwitcher
                    .padding(.horizontal)

                Group {
                    switch viewModel.selectedTab {
                    case .cpu: cpuTabContent
                    case .ram: ramTabContent
                    case .network: networkTabContent
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color("lightBlueDarkGreyColor"))
        .navigationTitle("Device Health")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadAllData() }
    }

    // MARK: - Tab Switcher
    private var tabSwitcher: some View {
        HStack(spacing: 10) {
            ForEach(DeviceHealthTab.allCases, id: \.self) { tab in
                let isSelected = viewModel.selectedTab == tab
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .background(
                        Capsule()
                            .fill(isSelected ? tab.color : Color("offWhiteAndGrayColor"))
                            .shadow(color: .black.opacity(isSelected ? 0.15 : 0.04), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Reusable Components
    private func infoRow(icon: String, label: String, value: String, iconColor: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .multilineTextAlignment(.trailing)
        }
    }

    private func infoCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
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
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - CPU Tab
    private var cpuTabContent: some View {
        VStack(spacing: 16) {
            // CPU Usage Gauge Card
            infoCard {
                VStack(spacing: 14) {
                    HStack {
                        Text("CPU Usage")
                            .font(.headline)
                        Spacer()
                        Text("\(homeViewModel.cpuUsage)%")
                            .font(.title2.bold())
                            .foregroundColor(.purple)
                    }

                    GeometryReader { geo in
                        let total = max(homeViewModel.cpuUser + homeViewModel.cpuSystem + homeViewModel.cpuIdle, 1)
                        HStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.purple)
                                .frame(width: geo.size.width * CGFloat(homeViewModel.cpuUser / total))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.orange)
                                .frame(width: geo.size.width * CGFloat(homeViewModel.cpuSystem / total))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green.opacity(0.4))
                        }
                    }
                    .frame(height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                    HStack(spacing: 12) {
                        legendItem(color: .purple, label: "User \(String(format: "%.0f%%", homeViewModel.cpuUser))")
                        legendItem(color: .orange, label: "System \(String(format: "%.0f%%", homeViewModel.cpuSystem))")
                        legendItem(color: .green.opacity(0.4), label: "Idle \(String(format: "%.0f%%", homeViewModel.cpuIdle))")
                        Spacer()
                    }
                }
            }

            // Device Info Card
            infoCard {
                infoRow(icon: "iphone", label: "Device", value: viewModel.deviceModel, iconColor: .purple)
                cardDivider()
                infoRow(icon: "gear", label: "iOS Version", value: viewModel.iOSVersion, iconColor: .purple)
                cardDivider()
                infoRow(icon: "cpu", label: "Processor", value: viewModel.processorInfo, iconColor: .purple)
            }

            // Thermal & System Card
            infoCard {
                infoRow(icon: "thermometer.medium", label: "Thermal State",
                        value: thermalStateText, iconColor: thermalStateColor)
                cardDivider()
                infoRow(icon: "leaf.fill", label: "Low Power Mode",
                        value: viewModel.isLowPowerMode ? "On" : "Off",
                        iconColor: .green)
            }

            // Uptime Card
            infoCard {
                infoRow(icon: "clock.fill", label: "Uptime",
                        value: formattedUptime, iconColor: .purple)
            }
        }
    }

    // MARK: CPU Computed Properties
    private var thermalStateText: String {
        switch viewModel.thermalState {
        case .nominal: return "Normal"
        case .fair: return "Warm"
        case .serious: return "Hot"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private var thermalStateColor: Color {
        switch viewModel.thermalState {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .gray
        }
    }

    private var batteryText: String {
        if viewModel.batteryLevel < 0 { return "Simulator" }
        return "\(Int(viewModel.batteryLevel * 100))%"
    }

    private var batteryColor: Color {
        let level = viewModel.batteryLevel
        if level < 0 { return .gray }
        if level <= 0.2 { return .red }
        if level <= 0.5 { return .orange }
        return .green
    }

    private var chargingText: String {
        switch viewModel.batteryState {
        case .charging: return "Charging"
        case .full: return "Full"
        case .unplugged: return "Not Charging"
        default: return "Unknown"
        }
    }

    private var formattedUptime: String {
        let totalSeconds = Int(viewModel.uptime)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    // MARK: - RAM Tab
    private var ramTabContent: some View {
        VStack(spacing: 16) {
            // Memory Gauge Card
            infoCard {
                VStack(spacing: 14) {
                    HStack {
                        Text("Memory Usage")
                            .font(.headline)
                        Spacer()
                        Text("\(homeViewModel.usedRAM.formatBytes()) / \(homeViewModel.totalRAM.formatBytes())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    GeometryReader { geo in
                        let total = max(Double(homeViewModel.totalRAM), 1)
                        HStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.red.opacity(0.8))
                                .frame(width: geo.size.width * CGFloat(Double(homeViewModel.wiredMemory) / total))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.orange)
                                .frame(width: geo.size.width * CGFloat(Double(homeViewModel.activeMemory) / total))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.yellow)
                                .frame(width: geo.size.width * CGFloat(Double(homeViewModel.inactiveMemory) / total))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green.opacity(0.5))
                        }
                    }
                    .frame(height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                    HStack(spacing: 12) {
                        legendItem(color: .red.opacity(0.8), label: "Wired")
                        legendItem(color: .orange, label: "Active")
                        legendItem(color: .yellow, label: "Inactive")
                        legendItem(color: .green.opacity(0.5), label: "Free")
                        Spacer()
                    }
                }
            }

            // Breakdown Card
            infoCard {
                infoRow(icon: "memorychip", label: "Total RAM",
                        value: homeViewModel.totalRAM.formatBytes(), iconColor: .indigo)
                cardDivider()
                infoRow(icon: "chart.bar.fill", label: "Used",
                        value: homeViewModel.usedRAM.formatBytes(), iconColor: .red)
                cardDivider()
                infoRow(icon: "chart.bar", label: "Available",
                        value: homeViewModel.availableRAM.formatBytes(), iconColor: .green)
                cardDivider()
                infoRow(icon: "app.fill", label: "App Footprint",
                        value: homeViewModel.appMemoryFootprint.formatBytes(), iconColor: .indigo)
            }

            // Boost Button
            Button {
                viewModel.boostMemory()
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isBoostingMemory {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "bolt.fill")
                    }
                    Text(viewModel.isBoostingMemory ? "Boosting..." : "Boost Memory")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color.indigo)
                        .shadow(color: .indigo.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isBoostingMemory)
            .opacity(viewModel.isBoostingMemory ? 0.7 : 1)
        }
    }

    // MARK: - Network Tab
    private var networkTabContent: some View {
        VStack(spacing: 16) {
            // Connection Card
            infoCard {
                infoRow(icon: "wifi", label: "Connection",
                        value: viewModel.connectionType, iconColor: .teal)
                cardDivider()
                infoRow(icon: "wifi.circle", label: "WiFi SSID",
                        value: viewModel.wifiSSID, iconColor: .teal)
            }

            // Details Card
            infoCard {
                infoRow(icon: "number", label: "IP Address",
                        value: viewModel.ipAddress, iconColor: .teal)
                cardDivider()
                infoRow(icon: "lock.shield", label: "VPN",
                        value: viewModel.isVPNActive ? "Active" : "Inactive",
                        iconColor: viewModel.isVPNActive ? .green : .gray)
                cardDivider()
                infoRow(icon: "network", label: "Interface",
                        value: viewModel.interfaceType, iconColor: .teal)
            }

            // Data Usage Card
            infoCard {
                infoRow(icon: "arrow.up.circle.fill", label: "Data Sent",
                        value: viewModel.dataSent.formatBytes(), iconColor: .blue)
                cardDivider()
                infoRow(icon: "arrow.down.circle.fill", label: "Data Received",
                        value: viewModel.dataReceived.formatBytes(), iconColor: .green)
            }

            // Speed Test Navigation Button
            Button {
                path.append(HomeDestination.speedTest)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "speedometer")
                    Text("Speed Test")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color.teal)
                        .shadow(color: .teal.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        DeviceHealthView(initialTab: .cpu, homeViewModel: HomeScreenViewModel(), path: .constant(NavigationPath()))
    }
}
