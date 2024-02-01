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
    private let queue = DispatchQueue.global(qos: .userInteractive)
    private var cancellables: Set<AnyCancellable> = []
    private var deviceInfoManager: DeviceInfoManager
    private var eventStore: EKEventStore
    private var fetchResultController: NSFetchedResultsController<DBAsset>?
    
    init(deviceInfoManager: DeviceInfoManager, eventStore: EKEventStore){
        self.deviceInfoManager = deviceInfoManager
        self.eventStore = eventStore
        super.init()
        self.deviceInfoManager.delegate = self
        setupFetchResultController()
        queue.async {
//            self.getPhotosAndVideosData()
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

    
    func setupFetchResultController(){
        if fetchResultController == nil{
            let request = DBAsset.fetchRequest()
            let dateSort = NSSortDescriptor(key: "creationDate", ascending: true)
            request.sortDescriptors = [dateSort]
            
            var predicates:[NSPredicate] = []
            
            predicates.append(NSPredicate(format: "groupTypeValue == %@", PHAssetGroupType.duplicate.rawValue))
            predicates.append(NSPredicate(format: "featurePrints != nil"))
            
            var compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
            
            fetchResultController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataManager.shared.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchResultController?.delegate = self
            
            do{
                try fetchResultController?.performFetch()
                updatePhotoAndVideosCountAndSize()
                
            } catch{
                print(error)
            }
        }
    }
    
    func updatePhotoAndVideosCountAndSize(){
        let assets = fetchResultController?.fetchedObjects ?? []
        photosAndVideosCount = assets.count
        self.photosAndVideosSize = assets.reduce(0) { $0 + $1.size }
    }


    
    
    func getPhotosAndVideosData(){
//        let fetchOptions = PHFetchOptions()
        let allPhotos = PHAsset.fetchAssets(with: .none)
        
        allPhotos.enumerateObjects { [weak self] asset, test, _ in
            self?.photosAndVideosSize += asset.getSize() ?? 0
            self?.photosAndVideosCount += 1
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
