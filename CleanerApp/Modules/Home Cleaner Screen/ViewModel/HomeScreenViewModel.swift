//
//  HomeScreenViewModel.swift
//  CleanerApp
//
//  Created by Manukant Harshmani Tyagi on 24/04/26.
//


import Foundation
import Contacts
import Photos
import EventKit

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
    @Published var systemStorage: Int64 = 0

    let contactStore = CNContactStore()
    private var deviceInfoTimer: Timer?

    // Storage breakdown (real values)
    var photosProgress: CGFloat {
        guard totalStorage > 0 else { return 0 }
        return CGFloat(Double(photosAndVideosSize ?? 0) / Double(totalStorage))
    }
    var appsProgress: CGFloat {
        guard totalStorage > 0 else { return 0 }
        let photosSize = photosAndVideosSize ?? 0
        let appsSize = max(0, usedStorage - photosSize - systemStorage)
        return CGFloat(Double(appsSize) / Double(totalStorage))
    }
    var otherProgress: CGFloat {
        guard totalStorage > 0 else { return 0 }
        return CGFloat(Double(systemStorage) / Double(totalStorage))
    }

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
            let values = try documentDirectory.resourceValues(forKeys: [
                .volumeAvailableCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeTotalCapacityKey
            ])
            if let totalSize = values.volumeTotalCapacity,
               let importantFree = values.volumeAvailableCapacityForImportantUsage {
                let rawTotal = Int64(totalSize)
                let marketedTotal = Self.marketedCapacity(for: rawTotal)
                let overhead = marketedTotal - rawTotal
                let used = rawTotal - importantFree + overhead
                let rawFree = values.volumeAvailableCapacity.map { Int64($0) } ?? importantFree
                let purgeable = max(0, importantFree - rawFree)
                DispatchQueue.main.async {
                    self.totalStorage = marketedTotal
                    self.usedStorage = used
                    self.systemStorage = purgeable
                }
            }
        } catch {
            print("Error getting storage: \(error)")
        }
    }

    /// Rounds raw filesystem capacity up to the nearest marketed size (e.g. ~125 GB → 128 GB).
    private static func marketedCapacity(for rawBytes: Int64) -> Int64 {
        let gb: Int64 = 1_000_000_000 // storage manufacturers use decimal GB
        let tiers: [Int64] = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 6144, 8192, 10240]
        let rawGB = rawBytes / gb
        for tier in tiers {
            if rawGB <= tier { return tier * gb }
        }
        return rawBytes
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
