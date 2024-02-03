//
//  CleanerViewModel.swift
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

class  CleanerViewModel: NSObject {

    @Published var availableRAM: UInt64 = 0
    @Published var eventsCount: Int?
    @Published var reminderCount: Int?
    @Published var photosAndVideosCount = 0
    @Published var photosAndVideosSize: Int64 = 0
    @Published var totalStorage: Int64 = 0
    @Published var usedStorage: Int64 = 0
    @Published var isProcessCompleted = false
    private let queue = DispatchQueue.global(qos: .userInteractive)
    private var cancellables: Set<AnyCancellable> = []
    private var deviceInfoManager: DeviceInfoManager
    private var eventStore: EKEventStore
    private var fetchResultController: NSFetchedResultsController<DBAsset>?
    private let allPhotosCount:Int = {
        let option = PHFetchOptions()
        return PHAsset.fetchAssets(with: .image, options: option).count
    }()
    
    init(deviceInfoManager: DeviceInfoManager, eventStore: EKEventStore){
        self.deviceInfoManager = deviceInfoManager
        self.eventStore = eventStore
        super.init()
        self.deviceInfoManager.delegate = self
//        setupFetchResultController()
        fetchPhotoAndvideosCountAndSize()
        
        queue.async {
//            self.getPhotosAndVideosData()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(contextDidSave(notification:)), name: .NSManagedObjectContextDidSave, object: CoreDataManager.customContext)
    }
    
    @objc func contextDidSave(notification: Notification) {
        
        CoreDataManager.secondCustomContext.perform {
            self.fetchPhotoAndvideosCountAndSize()
//            try? self.fetchResultController?.performFetch()
//            self.updatePhotoAndVideosCountAndSize()
        }
    }
    
    func startUpdatingDeivceInfo(){
        deviceInfoManager.startRAMUpdateTimer()
    }
    
    func stopUpdatingDeviceInfo(){
        deviceInfoManager.stopRamUpdateTimer()
    }
    
    func updateData(){
        
        queue.async {
            self.getCalendarData()
        }
        queue.async {
            self.getReminderData()
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

    
//    func setupFetchResultController(){
//        if fetchResultController == nil{
//            let request = DBAsset.fetchRequest()
//            let dateSort = NSSortDescriptor(key: "creationDate", ascending: true)
//            request.sortDescriptors = [dateSort]
//            request.predicate = NSPredicate(format: "isChecked == %@", NSNumber(value: true))
//            
//            fetchResultController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataManager.mainContext, sectionNameKeyPath: nil, cacheName: nil)
//            fetchResultController?.delegate = self
//            
//            do{
//                try fetchResultController?.performFetch()
//                updatePhotoAndVideosCountAndSize()
//                
//            } catch{
//                print(error)
//            }
//        }
//    }
    
    func fetchPhotoAndvideosCountAndSize(){
        let predicate = NSPredicate(format: "isChecked == %@", NSNumber(value: true))
        let assets = CoreDataManager.shared.fetchDBAssets(context: CoreDataManager.secondCustomContext, predicate: predicate)
        photosAndVideosCount = assets.count
        isProcessCompleted = assets.count == allPhotosCount
        self.photosAndVideosSize = assets.reduce(0) { $0 + $1.size }
    
    }
    
    func updatePhotoAndVideosCountAndSize(){
        let assets = fetchResultController?.fetchedObjects ?? []
        photosAndVideosCount = assets.count
        isProcessCompleted = assets.count == allPhotosCount
        self.photosAndVideosSize = assets.reduce(0) { $0 + $1.size }
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
        let predicate = self.eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predicate) { reminders in
            self.reminderCount = reminders?.count
        }
    }
    
    
    func fetchCalendarEvents() {
        let startDate = Calendar.current.date(byAdding: .year, value: -4, to: Date())!
        let endDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate!, calendars: nil)
        eventsCount = eventStore.events(matching: predicate).count
    }
    
    
}


//MARK: - Device Info Delegate
extension CleanerViewModel: DeviceInfoDelegate{
    func availableRAMDidUpdate(_ availableRAM: UInt64) {
        self.availableRAM = availableRAM
    }
}

extension CleanerViewModel: NSFetchedResultsControllerDelegate{
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updatePhotoAndVideosCountAndSize()
    }
}
