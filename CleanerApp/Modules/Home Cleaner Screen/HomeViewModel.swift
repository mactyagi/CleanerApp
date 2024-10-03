//
//  HomeViewModel.swift
//  CleanerApp
//
//  Created by Manu on 23/12/23.
//

import Foundation
import Combine
import EventKit
import Photos
import UIKit
import CoreData
import Contacts

class  HomeViewModel: NSObject {

    @Published var availableRAM: UInt64 = 0
    @Published var eventsCount: Int?
    @Published var reminderCount: Int?
    @Published var contactsCount: Int?
    @Published var photosAndVideosCount:Int = 0
    @Published var photosAndVideosSize: Int64?
    @Published var totalStorage: Int64 = 0
    @Published var usedStorage: Int64 = 0
    @Published var progress: Float = 0
    private let queue = DispatchQueue.global(qos: .userInteractive)
    private var cancellables: Set<AnyCancellable> = []
    private var deviceInfoManager: DeviceInfoManager
    let publisher = CurrentValueSubject<Double, Never>(0.0)
    var contactStore: CNContactStore
    init(deviceInfoManager: DeviceInfoManager, contactStore: CNContactStore){
        self.deviceInfoManager = deviceInfoManager
        self.contactStore = contactStore
        super.init()
        self.deviceInfoManager.delegate = self
    }
    
    

    
    func startUpdatingDeivceInfo(){
        deviceInfoManager.startRAMUpdateTimer()
    }
    
    func stopUpdatingDeviceInfo(){
        deviceInfoManager.stopRamUpdateTimer()
    }
    
    func updateData(){
        queue.async {
            self.getContactsData()
            self.getCalendarData()
            self.getReminderData()
            self.fetchPhotoAndvideosCountAndSize()
            self.startUpdatingDeivceInfo()
        }
        queue.async {
            self.getStorageInfo()
        }
        
    }

    
    func getStorageInfo() {
        let fileManager = FileManager.default
        let documentDirectory = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

        do {
            let values = try documentDirectory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey])

            if let totalSize = values.volumeTotalCapacity, let freeSize = values.volumeAvailableCapacityForImportantUsage {
                let usedSize = Int64(totalSize) - freeSize

                totalStorage = Int64(totalSize)
                usedStorage = usedSize
                
                
                print("Total Storage: \(Int64(totalSize).formatBytes())")
                print("Used Storage: \(usedSize.formatBytes())")
            }
        } catch {
            print("Error getting storage information: \(error.localizedDescription)")
        }
    }

    
    func fetchPhotoAndvideosCountAndSize(){
        
        let predicate = NSPredicate(format: "isChecked == %@", NSNumber(value: true))
        let assets = CoreDataManager.shared.fetchDBAssets(context: CoreDataManager.customContext, predicate: predicate)
        photosAndVideosCount = assets.count
        
        let option = PHFetchOptions()
        let allPHAssetCount =  PHAsset.fetchAssets(with: .image, options: option).count + PHAsset.fetchAssets(with: .video, options: option).count
        
        if allPHAssetCount == 0 && !assets.isEmpty{
            progress = 0
        }else{
            if assets.count == allPHAssetCount{
                progress = 1
            }else{
                progress = Float(assets.count)/Float(allPHAssetCount)
                CoreDataPHAssetManager.shared.startProcessingPhotos()
            }
        }
        self.photosAndVideosSize = assets.reduce(0) { $0 + $1.size }
        
        
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined, .denied:
            photosAndVideosSize = nil
            return
        default:
            break
        }
    }
    
    private func getContactsData(){
        
        if CNContactStore.authorizationStatus(for: .contacts) == .authorized{
            fetchContacts()
        }
    }
    private func fetchContacts() {
        let request = CNContactFetchRequest(keysToFetch: [])
        contactsCount = 0
        do {
            try contactStore.enumerateContacts(with: request) { _, _ in
                contactsCount! += 1
                
            }
            print("Total Contacts Count: \(contactsCount)")
        } catch {
            print("Error fetching contacts count: \(error.localizedDescription)")
        }
    }

    
   private func getCalendarData() {
       if #available(iOS 17.0, *) {
           if EKEventStore.authorizationStatus(for: .event) == .fullAccess{
                fetchCalendarEvents()
           }
       } else {
           if EKEventStore.authorizationStatus(for: .event) == .authorized{
               fetchCalendarEvents()
           }
       }
    }
    private func getReminderData() {
        if #available(iOS 17.0, *) {
            if EKEventStore.authorizationStatus(for: .reminder) == .fullAccess{
                 fetchReminders()
            }
        } else {
            if EKEventStore.authorizationStatus(for: .reminder) == .authorized{
                fetchReminders()
            }
        }
     }
    
    
    private func fetchReminders(){
        let eventStore = EKEventStore()
        let predicate = eventStore.predicateForReminders(in: nil)
        
        eventStore.fetchReminders(matching: predicate) { reminders in
            self.reminderCount = reminders?.count
        }
    }
    
    
    func fetchCalendarEvents() {
        let eventStore = EKEventStore()
        let startDate = Calendar.current.date(byAdding: .year, value: -4, to: Date())!
        let endDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate!, calendars: nil)
        eventsCount = eventStore.events(matching: predicate).count
    }
    
    
}


//MARK: - Device Info Delegate
extension HomeViewModel: DeviceInfoDelegate{
    func availableRAMDidUpdate(_ availableRAM: UInt64) {
        self.availableRAM = availableRAM
    }
}

