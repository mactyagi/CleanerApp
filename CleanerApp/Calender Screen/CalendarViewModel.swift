//
//  CalendarViewModel.swift
//  CleanerApp
//
//  Created by Manu on 24/12/23.
//

import Foundation
import EventKit
import Combine

class CalendarViewModel {
    
    var eventStore: EKEventStore
    var currentSegementType = SegmentType.Calendar
    @Published var isSelectedAll: Bool = true
    @Published var totalSelectedCount = 0
    @Published var isAuthorized = true
    @Published var titleLabelForAuthorizationAlert = ""
    @Published var subtitleForAlert = ""
    @Published var totalCount = 0
    @Published var unAuthorizedTitle = ""
    @Published var unAuthorizedNote = ""
    @Published var showLoader = false
    
    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
    }
    
    
    typealias eventType = (year:String, events:[CustomEKEvent])
    typealias reminderType = (year:String, reminders: [CustomEKReminder])
    @Published var allEvents: [eventType] = []{
        didSet{
            checkForEventsSelection()
        }
    }
    
    @Published var allReminder: [reminderType] = []{
        didSet{
            checkForReminderSelection()
        }
    }
    
    func updateValueFor(segment: SegmentType){
        showLoader = true
        switch segment{
        case .Calendar:
            checkForCalendarAutorization { [weak self] isGranted in
                if isGranted{
                    self?.checkForEventsSelection()
                }else{
                    self?.setNoteAndtitleLabelForUnAuthorizedState(segment: segment)
                }
                self?.isAuthorized = isGranted
                self?.showLoader = false
            }
        case .Reminder:
            checkForReminderAutorization { [weak self] isAuthorized in
                if isAuthorized{
                    self?.checkForReminderSelection()
                }else{
                    self?.setNoteAndtitleLabelForUnAuthorizedState(segment: segment)
                }
                self?.isAuthorized = isAuthorized
                self?.showLoader = false
            }
        }
        
        currentSegementType = segment
    }
    
    func setNoteAndtitleLabelForUnAuthorizedState(segment: SegmentType){
        var name = ""
        switch segment {
        case .Calendar:
            name = "Calendar"
        case .Reminder:
            name = "Reminders"
        }
        unAuthorizedTitle = "No Access to \(name)"
        unAuthorizedNote = "Access is needed to search completed \(name). Your \(name) will NOT be stored or used on any of our servers and will not be shared with third parties."
    }
    
    private func checkForReminderSelection(){
        var isSelected = true
        var selectedCount = 0
        var totalCount = 0
        for reminder in allReminder {
            let customReminders = reminder.reminders
            for customReminder in customReminders {
                totalCount += 1
                if customReminder.isSelected == false{
                    isSelected = false
                }else{
                    selectedCount += 1
                }
            }
        }
        totalSelectedCount = selectedCount
        self.totalCount = totalCount
        isSelectedAll = isSelected
    }
    private func checkForEventsSelection(){
        var isSelected = true
        var totalCount = 0
        var selectedCount = 0
        for event in allEvents {
            let customEvents = event.events
            for customEvent in customEvents {
                totalCount += 1
                if customEvent.isSelected == false{
                    isSelected = false
                }else{
                    selectedCount += 1
                }
            }
        }
        self.totalCount = totalCount
        totalSelectedCount = selectedCount
        isSelectedAll = isSelected
    }
    
    func selectAndDeselectAll(){
        isSelectedAll.toggle()
        switch currentSegementType{
        case .Calendar:
            selectionAndDeSelectionForAllEvents()
        case .Reminder:
            selectionAndDeselectionForAllReminder()
        }
    }
    
    private func selectionAndDeSelectionForAllEvents(){
        var newEvents = allEvents
        for (outerIndex, event) in newEvents.enumerated() {
            let customEvents = event.events
            for (innerIndex, customEvent) in customEvents.enumerated() {
                newEvents[outerIndex].events[innerIndex].isSelected = isSelectedAll
            }
        }
        allEvents = newEvents
    }
    
    private func selectionAndDeselectionForAllReminder(){
        var newEvents = allReminder
        for (outerIndex, reminder) in newEvents.enumerated() {
            let customReminders = reminder.reminders
            for (innerIndex, customReminder) in customReminders.enumerated() {
                newEvents[outerIndex].reminders[innerIndex].isSelected = isSelectedAll
            }
        }
        allReminder = newEvents
    }
    
    private func checkForCalendarAutorization(comp:@escaping(_ isGranted: Bool) -> ()) {
        if !self.allEvents.isEmpty{
            comp(true)
            return
        }
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                if granted {
                    self.fetchCalendarEvents()
                }
                comp(granted)
            }
        } else {
            eventStore.requestAccess(to: .event) { (granted, error) in
                if granted {
                    self.fetchCalendarEvents()
                }
                comp(granted)
            }
        }
    }
    
    
    
    private func checkForReminderAutorization(comp:@escaping(_ isAuthorized: Bool) -> ()){
        if self.allReminder.count != 0 {
            comp(true)
            return
        }
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToReminders { granted, error in
                if granted{
                    self.fetchReminders()
                }
                comp(granted)
            }
        } else {
            eventStore.requestAccess(to: .reminder) { (granted, error) in
                if granted{
                    self.fetchReminders()
                }
                comp(granted)
            }
        }
    }
    
    private func fetchReminders(){
        let predicate = self.eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predicate) { reminders in
            if let reminders = reminders {
                let customReminders = reminders.compactMap { CustomEKReminder(reminder: $0, isSelected: true)}
                let eventsGroup = Dictionary(grouping: customReminders, by: \.reminder.year)
                self.allReminder = eventsGroup.keys.compactMap { ($0, eventsGroup[$0]!.sorted(by: { ($0.reminder.creationDate ?? Date()) < ($1.reminder.creationDate ?? Date()) }))}.sorted(by: { $0.year > $1.year })
            }
        }
    }
    
    private func fetchCalendarEvents() {
        let startDate = Calendar.current.date(byAdding: .year, value: -4, to: Date())!
        let endDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate!, calendars: nil)
        let events = eventStore.events(matching: predicate)
        let customEvents = events.compactMap { CustomEKEvent(event: $0, isSelected: true)}
        let event = customEvents[0]
        print(event.event.calendar)
        print(event.event.description)
        let eventsGroup = Dictionary(grouping: customEvents, by: \.event.year)
        allEvents = eventsGroup.keys.compactMap { ($0, eventsGroup[$0]!.sorted(by: { $0.event.startDate < $1.event.startDate }))}.sorted(by: { $0.year > $1.year })
        
    }
    
    func deleteData(){
        showLoader = true
        switch currentSegementType {
        case .Calendar:
            deleteEvents()
        case .Reminder:
            deleteReminders()
        }
        showLoader = false
    }
    
    
    private func deleteReminders(){
        var remainingReminders: [CustomEKReminder] = []
        for reminderTouple in self.allReminder {
            let customReminders = reminderTouple.reminders
            for customReminder in customReminders {
                if customReminder.isSelected{
                    do{
                        try eventStore.remove(customReminder.reminder, commit: true)
                    }catch{
                        print(error)
                    }
                }else{
                    remainingReminders.append(customReminder)
                }
            }
        }
        
        let eventsGroup = Dictionary(grouping: remainingReminders, by: \.reminder.year)
        self.allReminder = eventsGroup.keys.compactMap { ($0, eventsGroup[$0]!.sorted(by: { ($0.reminder.creationDate ?? Date()) < ($1.reminder.creationDate ?? Date())}))}.sorted(by: { $0.year > $1.year })
    }
    
    
    private func deleteEvents(){
        var remainingEvents: [CustomEKEvent] = []
        for allEvent in allEvents {
            let events = allEvent.events
            for event in events {
                if event.isSelected{
                    do {
                        try eventStore.remove(event.event, span: .thisEvent)
                    }catch{
                        print(error)
                    }
                }else{
                    remainingEvents.append(event)
                }
            }
        }
        
        let eventsGroup = Dictionary(grouping: remainingEvents, by: \.event.year)
        allEvents = eventsGroup.keys.compactMap { ($0, eventsGroup[$0]!.sorted(by: { $0.event.startDate > $1.event.startDate }))}.sorted(by: { $0.year > $1.year })
    }
}
