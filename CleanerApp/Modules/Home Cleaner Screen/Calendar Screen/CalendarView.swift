//
//  CalendarView.swift
//  CleanerApp
//
//  SwiftUI version of CalendarViewController
//  - Segmented control for Calendar/Reminder switching
//  - Events/Reminders grouped by year
//  - Select All / Deselect All functionality
//  - Delete with confirmation
//  - Authorization handling
//

import SwiftUI
import EventKit

// MARK: - CalendarView
struct CalendarView: View {
    @StateObject private var viewModel: CalendarSwiftUIViewModel
    @State private var showDeleteAlert = false
    @State private var selectedSegment: SegmentType = .Calendar

    init(eventStore: EKEventStore = EKEventStore()) {
        _viewModel = StateObject(wrappedValue: CalendarSwiftUIViewModel(eventStore: eventStore))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header with segment control
                CalendarHeaderView(
                    selectedSegment: $selectedSegment,
                    onSegmentChange: { segment in
                        viewModel.updateValueFor(segment: segment)
                    }
                )

                // Authorization warning view
                if !viewModel.isAuthorized {
                    CalendarAuthorizationView(
                        title: viewModel.unAuthorizedTitle,
                        note: viewModel.unAuthorizedNote,
                        onGoToSettings: openSettings
                    )
                    Spacer()
                } else {
                    // Stats bar
                    CalendarStatsBar(
                        selectedCount: viewModel.totalSelectedCount,
                        totalCount: viewModel.totalCount,
                        isAllSelected: viewModel.isSelectedAll,
                        onToggleAll: {
                            vibrate()
                            viewModel.selectAndDeselectAll()
                        }
                    )

                    // Content based on segment
                    if selectedSegment == .Calendar {
                        CVEventsList(
                            events: viewModel.allEvents,
                            onToggleSelection: { sectionIndex, itemIndex in
                                viewModel.toggleEventSelection(section: sectionIndex, index: itemIndex)
                            }
                        )
                    } else {
                        CVRemindersList(
                            reminders: viewModel.allReminder,
                            onToggleSelection: { sectionIndex, itemIndex in
                                viewModel.toggleReminderSelection(section: sectionIndex, index: itemIndex)
                            }
                        )
                    }
                }
            }

            // Delete button
            if viewModel.isAuthorized && viewModel.totalSelectedCount > 0 {
                CVDeleteButton(
                    count: viewModel.totalSelectedCount,
                    segmentType: selectedSegment,
                    onDelete: { showDeleteAlert = true }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: viewModel.totalSelectedCount)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isAuthorized && viewModel.totalCount > 0 {
                    Button(viewModel.isSelectedAll ? "Deselect All" : "Select All") {
                        vibrate()
                        viewModel.selectAndDeselectAll()
                    }
                }
            }
        }
        .alert("Delete \(viewModel.totalSelectedCount) \(eventOrEvents)?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                logEvent(selectedSegment == .Calendar ?
                        Event.CalendarScreen.eventDeleted.rawValue :
                        Event.CalendarScreen.reminderDeleted.rawValue,
                        parameter: ["count": viewModel.totalSelectedCount])
                viewModel.deleteData()
            }
            Button("Cancel", role: .cancel) {
                logEvent(selectedSegment == .Calendar ?
                        Event.CalendarScreen.eventDeleteCancel.rawValue :
                        Event.CalendarScreen.reminderDeleteCancel.rawValue,
                        parameter: nil)
            }
        } message: {
            Text("\(eventOrEvents.capitalized) will be removed from the \(selectedSegment == .Calendar ? "Calendar" : "Reminders")")
        }
        .overlay {
            if viewModel.showLoader {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .onAppear {
            logEvent(Event.CalendarScreen.appear.rawValue, parameter: nil)
            viewModel.updateValueFor(segment: selectedSegment)
        }
        .onDisappear {
            logEvent(Event.CalendarScreen.disappear.rawValue, parameter: nil)
        }
    }

    private var navigationTitle: String {
        guard viewModel.isAuthorized && viewModel.totalCount > 0 else { return "" }
        return "\(viewModel.totalSelectedCount) \(eventOrEvents) selected"
    }

    private var eventOrEvents: String {
        viewModel.totalSelectedCount == 1 ? "event" : "events"
    }

    private func openSettings() {
        logEvent(Event.CalendarScreen.goToSettingButtonPressed.rawValue, parameter: nil)
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Header with Segment Control
struct CalendarHeaderView: View {
    @Binding var selectedSegment: SegmentType
    let onSegmentChange: (SegmentType) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Picker("Type", selection: $selectedSegment) {
                Text("Calendar").tag(SegmentType.Calendar)
                Text("Reminder").tag(SegmentType.Reminder)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .onChange(of: selectedSegment) { newValue in
                vibrate()
                onSegmentChange(newValue)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

// MARK: - Authorization View
struct CalendarAuthorizationView: View {
    let title: String
    let note: String
    let onGoToSettings: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(Color(uiColor: .systemGray))

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color(uiColor: .label))
                .multilineTextAlignment(.center)

            Text(note)
                .font(.subheadline)
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onGoToSettings) {
                HStack {
                    Image(systemName: "gear")
                    Text("Go to Settings")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color(uiColor: .darkBlue))
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }
}

// MARK: - Stats Bar
struct CalendarStatsBar: View {
    let selectedCount: Int
    let totalCount: Int
    let isAllSelected: Bool
    let onToggleAll: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(uiColor: .darkBlue))
                Text("\(selectedCount) of \(totalCount) selected")
                    .font(.subheadline)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }

            Spacer()

            Button(action: onToggleAll) {
                Text(isAllSelected ? "Deselect All" : "Select All")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isAllSelected ? .white : Color(uiColor: .darkBlue))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        isAllSelected ?
                        Color(uiColor: .darkBlue) :
                        Color(uiColor: .darkBlue).opacity(0.1)
                    )
                    .cornerRadius(20)
            }
            .disabled(totalCount == 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

// MARK: - Events List
struct CVEventsList: View {
    let events: [(year: String, events: [CustomEKEvent])]
    let onToggleSelection: (Int, Int) -> Void

    var body: some View {
        if events.isEmpty {
            CVEmptyView(type: .Calendar)
        } else {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(Array(events.enumerated()), id: \.element.year) { sectionIndex, section in
                        Section {
                            ForEach(Array(section.events.enumerated()), id: \.element.event.eventIdentifier) { itemIndex, customEvent in
                                CVEventRow(
                                    event: customEvent,
                                    isLast: itemIndex == section.events.count - 1,
                                    onToggle: {
                                        vibrate()
                                        onToggleSelection(sectionIndex, itemIndex)
                                    }
                                )
                            }
                        } header: {
                            CVSectionHeader(title: section.year)
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

// MARK: - Reminders List
struct CVRemindersList: View {
    let reminders: [(year: String, reminders: [CustomEKReminder])]
    let onToggleSelection: (Int, Int) -> Void

    var body: some View {
        if reminders.isEmpty {
            CVEmptyView(type: .Reminder)
        } else {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(Array(reminders.enumerated()), id: \.element.year) { sectionIndex, section in
                        Section {
                            ForEach(Array(section.reminders.enumerated()), id: \.element.reminder.calendarItemIdentifier) { itemIndex, customReminder in
                                CVReminderRow(
                                    reminder: customReminder,
                                    isLast: itemIndex == section.reminders.count - 1,
                                    onToggle: {
                                        vibrate()
                                        onToggleSelection(sectionIndex, itemIndex)
                                    }
                                )
                            }
                        } header: {
                            CVSectionHeader(title: section.year)
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

// MARK: - Section Header
struct CVSectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color(uiColor: .label))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(UIColor(named: "lightGrayAndDarkGray2Color") ?? .systemGray5))
    }
}

// MARK: - Event Row
struct CVEventRow: View {
    let event: CustomEKEvent
    let isLast: Bool
    let onToggle: () -> Void

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MMM-yyyy"
        return formatter.string(from: event.event.startDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Selection indicator
                    Image(systemName: event.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(event.isSelected ? Color(uiColor: .darkBlue) : Color(uiColor: .systemGray3))

                    // Event info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.event.title ?? "No Title")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(Color(uiColor: .label))
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Label(formattedDate, systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(Color(uiColor: .secondaryLabel))

                            if let calendarTitle = event.event.calendar?.title {
                                Text("•")
                                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                                Text(calendarTitle)
                                    .font(.caption)
                                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                                    .lineLimit(1)
                            }
                        }
                    }

                    Spacer()

                    // Calendar color indicator
                    if let calendarColor = event.event.calendar?.cgColor {
                        Circle()
                            .fill(Color(cgColor: calendarColor))
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)

            if !isLast {
                Divider()
                    .padding(.leading, 52)
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
}

// MARK: - Reminder Row
struct CVReminderRow: View {
    let reminder: CustomEKReminder
    let isLast: Bool
    let onToggle: () -> Void

    private var formattedDate: String {
        guard let date = reminder.reminder.creationDate else { return "No Date" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MMM-yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Selection indicator
                    Image(systemName: reminder.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(reminder.isSelected ? Color(uiColor: .darkBlue) : Color(uiColor: .systemGray3))

                    // Reminder info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reminder.reminder.title ?? "No Title")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(Color(uiColor: .label))
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Label(formattedDate, systemImage: "bell")
                                .font(.caption)
                                .foregroundColor(Color(uiColor: .secondaryLabel))

                            if let calendarTitle = reminder.reminder.calendar?.title {
                                Text("•")
                                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                                Text(calendarTitle)
                                    .font(.caption)
                                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                                    .lineLimit(1)
                            }
                        }
                    }

                    Spacer()

                    // Completion status
                    if reminder.reminder.isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)

            if !isLast {
                Divider()
                    .padding(.leading, 52)
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
}

// MARK: - Empty View
struct CVEmptyView: View {
    let type: SegmentType

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: type == .Calendar ? "calendar" : "bell.slash")
                .font(.system(size: 50))
                .foregroundColor(Color(uiColor: .tertiaryLabel))

            Text(type == .Calendar ? "No Past Events" : "No Reminders")
                .font(.headline)
                .foregroundColor(Color(uiColor: .secondaryLabel))

            Text(type == .Calendar ?
                 "Past calendar events will appear here" :
                 "Your reminders will appear here")
                .font(.subheadline)
                .foregroundColor(Color(uiColor: .tertiaryLabel))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

// MARK: - Delete Button
struct CVDeleteButton: View {
    let count: Int
    let segmentType: SegmentType
    let onDelete: () -> Void

    private var eventText: String {
        count == 1 ? "Event" : "Events"
    }

    var body: some View {
        Button(action: onDelete) {
            HStack(spacing: 10) {
                Image(systemName: "trash.fill")
                Text("Delete \(count) \(eventText)")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(16)
            .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(
            Color(uiColor: .systemGroupedBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
        )
    }
}

// MARK: - SwiftUI ViewModel
class CalendarSwiftUIViewModel: ObservableObject {
    var eventStore: EKEventStore
    var currentSegmentType = SegmentType.Calendar

    @Published var isSelectedAll: Bool = true
    @Published var totalSelectedCount = 0
    @Published var isAuthorized = true
    @Published var totalCount = 0
    @Published var unAuthorizedTitle = ""
    @Published var unAuthorizedNote = ""
    @Published var showLoader = false

    typealias EventType = (year: String, events: [CustomEKEvent])
    typealias ReminderType = (year: String, reminders: [CustomEKReminder])

    @Published var allEvents: [EventType] = [] {
        didSet {
            logEvent(Event.CalendarScreen.eventCount.rawValue, parameter: ["count": allEvents.count])
            checkForEventsSelection()
        }
    }

    @Published var allReminder: [ReminderType] = [] {
        didSet {
            logEvent(Event.CalendarScreen.reminderCount.rawValue, parameter: ["count": allReminder.count])
            checkForReminderSelection()
        }
    }

    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
    }

    func updateValueFor(segment: SegmentType) {
        showLoader = true
        currentSegmentType = segment

        switch segment {
        case .Calendar:
            logEvent(Event.CalendarScreen.currentSegment.rawValue, parameter: ["type": "Calendar"])
            checkForCalendarAuthorization { [weak self] isGranted in
                DispatchQueue.main.async {
                    logEvent(Event.CalendarScreen.calendarAuthorization.rawValue, parameter: ["isAuthorized": isGranted])
                    if isGranted {
                        self?.checkForEventsSelection()
                    } else {
                        self?.setNoteAndTitleForUnauthorizedState(segment: segment)
                    }
                    self?.isAuthorized = isGranted
                    self?.showLoader = false
                }
            }
        case .Reminder:
            logEvent(Event.CalendarScreen.currentSegment.rawValue, parameter: ["type": "Reminder"])
            checkForReminderAuthorization { [weak self] isAuthorized in
                DispatchQueue.main.async {
                    logEvent(Event.CalendarScreen.reminderAuthorization.rawValue, parameter: ["isAuthorized": isAuthorized])
                    if isAuthorized {
                        self?.checkForReminderSelection()
                    } else {
                        self?.setNoteAndTitleForUnauthorizedState(segment: segment)
                    }
                    self?.isAuthorized = isAuthorized
                    self?.showLoader = false
                }
            }
        }
    }

    func toggleEventSelection(section: Int, index: Int) {
        allEvents[section].events[index].isSelected.toggle()
    }

    func toggleReminderSelection(section: Int, index: Int) {
        allReminder[section].reminders[index].isSelected.toggle()
    }

    func selectAndDeselectAll() {
        isSelectedAll.toggle()
        switch currentSegmentType {
        case .Calendar:
            selectAndDeselectAllEvents()
        case .Reminder:
            selectAndDeselectAllReminders()
        }
    }

    func deleteData() {
        showLoader = true
        switch currentSegmentType {
        case .Calendar:
            deleteEvents()
        case .Reminder:
            deleteReminders()
        }
        showLoader = false
    }

    func sortData(order: CalendarSortOrder, segment: SegmentType) {
        switch segment {
        case .Calendar:
            let ascending = order == .oldest
            var sortedEvents = allEvents
            for (sectionIdx, section) in sortedEvents.enumerated() {
                sortedEvents[sectionIdx].events = section.events.sorted {
                    ascending ? $0.event.startDate < $1.event.startDate : $0.event.startDate > $1.event.startDate
                }
            }
            sortedEvents.sort { ascending ? $0.year < $1.year : $0.year > $1.year }
            allEvents = sortedEvents

        case .Reminder:
            let ascending = order == .oldest
            var sortedReminders = allReminder
            for (sectionIdx, section) in sortedReminders.enumerated() {
                sortedReminders[sectionIdx].reminders = section.reminders.sorted {
                    let date1 = $0.reminder.creationDate ?? Date.distantPast
                    let date2 = $1.reminder.creationDate ?? Date.distantPast
                    return ascending ? date1 < date2 : date1 > date2
                }
            }
            sortedReminders.sort { ascending ? $0.year < $1.year : $0.year > $1.year }
            allReminder = sortedReminders
        }
    }

    // MARK: - Private Methods

    private func setNoteAndTitleForUnauthorizedState(segment: SegmentType) {
        let name = segment == .Calendar ? "Calendar" : "Reminders"
        unAuthorizedTitle = "No Access to \(name)"
        unAuthorizedNote = "Access is needed to search completed \(name). Your \(name) will NOT be stored or used on any of our servers and will not be shared with third parties."
    }

    private func checkForEventsSelection() {
        var isSelected = true
        var selectedCount = 0
        var total = 0

        for event in allEvents {
            for customEvent in event.events {
                total += 1
                if !customEvent.isSelected {
                    isSelected = false
                } else {
                    selectedCount += 1
                }
            }
        }

        totalSelectedCount = selectedCount
        totalCount = total
        isSelectedAll = isSelected
    }

    private func checkForReminderSelection() {
        var isSelected = true
        var selectedCount = 0
        var total = 0

        for reminder in allReminder {
            for customReminder in reminder.reminders {
                total += 1
                if !customReminder.isSelected {
                    isSelected = false
                } else {
                    selectedCount += 1
                }
            }
        }

        totalSelectedCount = selectedCount
        totalCount = total
        isSelectedAll = isSelected
    }

    private func selectAndDeselectAllEvents() {
        var newEvents = allEvents
        for (outerIndex, event) in newEvents.enumerated() {
            for innerIndex in event.events.indices {
                newEvents[outerIndex].events[innerIndex].isSelected = isSelectedAll
            }
        }
        allEvents = newEvents
    }

    private func selectAndDeselectAllReminders() {
        var newReminders = allReminder
        for (outerIndex, reminder) in newReminders.enumerated() {
            for innerIndex in reminder.reminders.indices {
                newReminders[outerIndex].reminders[innerIndex].isSelected = isSelectedAll
            }
        }
        allReminder = newReminders
    }

    private func checkForCalendarAuthorization(completion: @escaping (Bool) -> Void) {
        if !allEvents.isEmpty {
            completion(true)
            return
        }

        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, _ in
                if granted {
                    self.fetchCalendarEvents()
                }
                completion(granted)
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, _ in
                if granted {
                    self.fetchCalendarEvents()
                }
                completion(granted)
            }
        }
    }

    private func checkForReminderAuthorization(completion: @escaping (Bool) -> Void) {
        if !allReminder.isEmpty {
            completion(true)
            return
        }

        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToReminders { granted, _ in
                if granted {
                    self.fetchReminders()
                }
                completion(granted)
            }
        } else {
            eventStore.requestAccess(to: .reminder) { granted, _ in
                if granted {
                    self.fetchReminders()
                }
                completion(granted)
            }
        }
    }

    private func fetchCalendarEvents() {
        let startDate = Calendar.current.date(byAdding: .year, value: -4, to: Date())!
        let endDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        let customEvents = events.compactMap { CustomEKEvent(event: $0, isSelected: true) }
        let eventsGroup = Dictionary(grouping: customEvents, by: \.event.year)

        DispatchQueue.main.async {
            self.allEvents = eventsGroup.keys.compactMap {
                ($0, eventsGroup[$0]!.sorted(by: { $0.event.startDate > $1.event.startDate }))
            }.sorted(by: { $0.year > $1.year })
        }
    }

    private func fetchReminders() {
        let predicate = eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predicate) { reminders in
            guard let reminders = reminders else { return }
            let customReminders = reminders.compactMap { CustomEKReminder(reminder: $0, isSelected: true) }
            let remindersGroup = Dictionary(grouping: customReminders, by: \.reminder.year)

            DispatchQueue.main.async {
                self.allReminder = remindersGroup.keys.compactMap {
                    ($0, remindersGroup[$0]!.sorted(by: { ($0.reminder.creationDate ?? Date()) < ($1.reminder.creationDate ?? Date()) }))
                }.sorted(by: { $0.year > $1.year })
            }
        }
    }

    private func deleteEvents() {
        var remainingEvents: [CustomEKEvent] = []
        var selectedCount = 0

        for allEvent in allEvents {
            for event in allEvent.events {
                if event.isSelected {
                    selectedCount += 1
                    do {
                        try eventStore.remove(event.event, span: .thisEvent)
                    } catch {
                        print(error)
                    }
                } else {
                    remainingEvents.append(event)
                }
            }
        }

        logEvent(Event.CalendarScreen.eventDeleted.rawValue, parameter: ["count": selectedCount])

        let eventsGroup = Dictionary(grouping: remainingEvents, by: \.event.year)
        allEvents = eventsGroup.keys.compactMap {
            ($0, eventsGroup[$0]!.sorted(by: { $0.event.startDate > $1.event.startDate }))
        }.sorted(by: { $0.year > $1.year })
    }

    private func deleteReminders() {
        var remainingReminders: [CustomEKReminder] = []
        var selectedCount = 0

        for reminderTuple in allReminder {
            for customReminder in reminderTuple.reminders {
                if customReminder.isSelected {
                    selectedCount += 1
                    do {
                        try eventStore.remove(customReminder.reminder, commit: true)
                    } catch {
                        print(error)
                    }
                } else {
                    remainingReminders.append(customReminder)
                }
            }
        }

        logEvent(Event.CalendarScreen.reminderDeleted.rawValue, parameter: ["count": selectedCount])

        let remindersGroup = Dictionary(grouping: remainingReminders, by: \.reminder.year)
        allReminder = remindersGroup.keys.compactMap {
            ($0, remindersGroup[$0]!.sorted(by: { ($0.reminder.creationDate ?? Date()) < ($1.reminder.creationDate ?? Date()) }))
        }.sorted(by: { $0.year > $1.year })
    }
}

// MARK: - Preview
#Preview("Calendar View") {
    NavigationView {
        CalendarView()
    }
}
