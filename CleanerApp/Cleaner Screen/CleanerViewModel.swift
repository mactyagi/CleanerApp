//
//  CleanerViewModel.swift
//  CleanerApp
//
//  Created by Manu on 23/12/23.
//

import Foundation
import Combine
import EventKit

class  CleanerViewModel {

    @Published var availableRAM: UInt64 = 0
    @Published var eventsCount: Int?
    @Published var reminderCount: Int?
    private var cancellables: Set<AnyCancellable> = []
    private var deviceInfoManager: DeviceInfoManager
    private var eventStore: EKEventStore
    init(deviceInfoManager: DeviceInfoManager, eventStore: EKEventStore){
        self.deviceInfoManager = deviceInfoManager
        self.eventStore = eventStore
        self.deviceInfoManager.delegate = self
        CoreDataPHAssetManager.shared.startProcess()
    }
    
    
    func startUpdatingDeivceInfo(){
        deviceInfoManager.startRAMUpdateTimer()
    }
    
    func stopUpdatingDeviceInfo(){
        deviceInfoManager.stopRamUpdateTimer()
    }
    
    func updateData(){
        getCalendarData()
        getReminderData()
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
