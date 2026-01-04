//
//  CalendarView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI
import EventKit

struct CalendarView: View {
    @StateObject private var viewModel = CalendarSwiftUIViewModel()
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            Color.lightBlueDarkGrey
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Segment Control
                Picker("Type", selection: $viewModel.currentSegment) {
                    Text("Events").tag(SegmentType.Calendar)
                    Text("Reminders").tag(SegmentType.Reminder)
                }
                .pickerStyle(.segmented)
                .padding()

                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading...")
                    Spacer()
                } else if !viewModel.isAuthorized {
                    unauthorizedView
                } else if viewModel.isEmpty {
                    emptyStateView
                } else {
                    listContent
                }
            }
        }
        .navigationTitle(viewModel.titleText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(viewModel.isAllSelected ? "Deselect All" : "Select All") {
                    viewModel.toggleSelectAll()
                }
                .disabled(viewModel.isEmpty)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.isAuthorized && viewModel.selectedCount > 0 {
                deleteButtonView
            }
        }
        .alert("Delete \(viewModel.selectedCount) \(viewModel.selectedCount > 1 ? "events" : "event")?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                logCancelEvent()
            }
            Button("Delete", role: .destructive) {
                viewModel.deleteSelected()
            }
        } message: {
            Text("\(viewModel.selectedCount > 1 ? "Events" : "Event") will be removed from the \(viewModel.currentSegment == .Calendar ? "Calendar" : "Reminders")")
        }
        .onAppear {
            logEvent(Event.CalendarScreen.loaded.rawValue, parameter: nil)
        }
        .onChange(of: viewModel.currentSegment) { _ in
            viewModel.loadData()
        }
    }

    // MARK: - Unauthorized View

    private var unauthorizedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: viewModel.currentSegment == .Calendar ? "calendar.badge.exclamationmark" : "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(viewModel.unauthorizedTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text(viewModel.unauthorizedNote)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Go to Settings") {
                logEvent(Event.CalendarScreen.goToSettingButtonPressed.rawValue, parameter: nil)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)

            Spacer()
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: viewModel.currentSegment == .Calendar ? "calendar" : "checklist")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No \(viewModel.currentSegment == .Calendar ? "Past Events" : "Reminders")")
                .font(.title2)
                .fontWeight(.semibold)

            Text(viewModel.currentSegment == .Calendar
                 ? "Past calendar events will appear here"
                 : "Your reminders will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    // MARK: - List Content

    private var listContent: some View {
        List {
            if viewModel.currentSegment == .Calendar {
                ForEach(viewModel.eventSections, id: \.year) { section in
                    Section {
                        ForEach(Array(section.events.enumerated()), id: \.offset) { index, event in
                            EventRowView(event: event) {
                                viewModel.toggleEventSelection(year: section.year, index: index)
                            }
                        }
                    } header: {
                        Text(section.year)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
            } else {
                ForEach(viewModel.reminderSections, id: \.year) { section in
                    Section {
                        ForEach(Array(section.reminders.enumerated()), id: \.offset) { index, reminder in
                            ReminderRowView(reminder: reminder) {
                                viewModel.toggleReminderSelection(year: section.year, index: index)
                            }
                        }
                    } header: {
                        Text(section.year)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Delete Button

    private var deleteButtonView: some View {
        Button {
            logEvent(Event.CalendarScreen.deleteButtonPressed.rawValue, parameter: ["count": viewModel.selectedCount])
            showDeleteAlert = true
        } label: {
            VStack(spacing: 4) {
                Text("Delete \(viewModel.selectedCount) Selected")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(20)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func logCancelEvent() {
        switch viewModel.currentSegment {
        case .Calendar:
            logEvent(Event.CalendarScreen.eventDeleteCancel.rawValue, parameter: nil)
        case .Reminder:
            logEvent(Event.CalendarScreen.reminderDeleteCancel.rawValue, parameter: nil)
        }
    }
}

// MARK: - Event Row View

struct EventRowView: View {
    let event: CustomEKEvent
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Image(systemName: event.isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(event.isSelected ? .blue : .gray)
                .font(.title3)

            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.event.title ?? "Untitled Event")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let startDate = event.event.startDate {
                        Text(startDate.toString(formatType: .MMMdyyyy))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let location = event.event.location, !location.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Calendar color indicator
            if let calendar = event.event.calendar {
                Circle()
                    .fill(Color(cgColor: calendar.cgColor))
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Reminder Row View

struct ReminderRowView: View {
    let reminder: CustomEKReminder
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Image(systemName: reminder.isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(reminder.isSelected ? .blue : .gray)
                .font(.title3)

            // Reminder details
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.reminder.title ?? "Untitled Reminder")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                if let creationDate = reminder.reminder.creationDate {
                    Text(creationDate.toString(formatType: .MMMdyyyy))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Completion status
            if reminder.reminder.isCompleted {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - ViewModel

@MainActor
class CalendarSwiftUIViewModel: ObservableObject {
    @Published var currentSegment: SegmentType = .Calendar
    @Published var eventSections: [EventSection] = []
    @Published var reminderSections: [ReminderSection] = []
    @Published var isLoading: Bool = false
    @Published var isAuthorized: Bool = true
    @Published var isAllSelected: Bool = true

    private let eventStore = EKEventStore()

    var selectedCount: Int {
        switch currentSegment {
        case .Calendar:
            return eventSections.flatMap { $0.events }.filter { $0.isSelected }.count
        case .Reminder:
            return reminderSections.flatMap { $0.reminders }.filter { $0.isSelected }.count
        }
    }

    var totalCount: Int {
        switch currentSegment {
        case .Calendar:
            return eventSections.flatMap { $0.events }.count
        case .Reminder:
            return reminderSections.flatMap { $0.reminders }.count
        }
    }

    var isEmpty: Bool {
        switch currentSegment {
        case .Calendar:
            return eventSections.isEmpty
        case .Reminder:
            return reminderSections.isEmpty
        }
    }

    var titleText: String {
        guard isAuthorized && !isEmpty else { return "Calendar" }
        let eventWord = selectedCount == 1 ? "event" : "events"
        return "\(selectedCount) \(eventWord) selected"
    }

    var unauthorizedTitle: String {
        currentSegment == .Calendar ? "No Access to Calendar" : "No Access to Reminders"
    }

    var unauthorizedNote: String {
        let name = currentSegment == .Calendar ? "Calendar" : "Reminders"
        return "Access is needed to search completed \(name). Your \(name) will NOT be stored or used on any of our servers and will not be shared with third parties."
    }

    init() {
        loadData()
    }

    func loadData() {
        isLoading = true

        switch currentSegment {
        case .Calendar:
            logEvent(Event.CalendarScreen.currentSegment.rawValue, parameter: ["type": "Calendar"])
            requestCalendarAccess()
        case .Reminder:
            logEvent(Event.CalendarScreen.currentSegment.rawValue, parameter: ["type": "Reminder"])
            requestReminderAccess()
        }
    }

    private func requestCalendarAccess() {
        if !eventSections.isEmpty {
            isAuthorized = true
            isLoading = false
            checkEventSelection()
            return
        }

        Task {
            do {
                var granted = false
                if #available(iOS 17.0, *) {
                    granted = try await eventStore.requestFullAccessToEvents()
                } else {
                    granted = try await eventStore.requestAccess(to: .event)
                }

                logEvent(Event.CalendarScreen.calendarAuthorization.rawValue, parameter: ["isAuthorized": granted])

                await MainActor.run {
                    self.isAuthorized = granted
                    if granted {
                        self.fetchCalendarEvents()
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isAuthorized = false
                    self.isLoading = false
                }
            }
        }
    }

    private func requestReminderAccess() {
        if !reminderSections.isEmpty {
            isAuthorized = true
            isLoading = false
            checkReminderSelection()
            return
        }

        Task {
            do {
                var granted = false
                if #available(iOS 17.0, *) {
                    granted = try await eventStore.requestFullAccessToReminders()
                } else {
                    granted = try await eventStore.requestAccess(to: .reminder)
                }

                logEvent(Event.CalendarScreen.reminderAuthorization.rawValue, parameter: ["isAuthorized": granted])

                await MainActor.run {
                    self.isAuthorized = granted
                    if granted {
                        self.fetchReminders()
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isAuthorized = false
                    self.isLoading = false
                }
            }
        }
    }

    private func fetchCalendarEvents() {
        let startDate = Calendar.current.date(byAdding: .year, value: -4, to: Date())!
        let endDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)

        let customEvents = events.map { CustomEKEvent(event: $0, isSelected: true) }
        let grouped = Dictionary(grouping: customEvents) { $0.event.year }

        eventSections = grouped.map { year, events in
            EventSection(year: year, events: events.sorted { $0.event.startDate > $1.event.startDate })
        }.sorted { $0.year > $1.year }

        logEvent(Event.CalendarScreen.eventCount.rawValue, parameter: ["count": eventSections.flatMap { $0.events }.count])
        checkEventSelection()
    }

    private func fetchReminders() {
        let predicate = eventStore.predicateForReminders(in: nil)

        eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
            guard let self = self, let reminders = reminders else { return }

            let customReminders = reminders.map { CustomEKReminder(reminder: $0, isSelected: true) }
            let grouped = Dictionary(grouping: customReminders) { $0.reminder.year }

            Task { @MainActor in
                self.reminderSections = grouped.map { year, reminders in
                    ReminderSection(year: year, reminders: reminders.sorted { ($0.reminder.creationDate ?? Date()) < ($1.reminder.creationDate ?? Date()) })
                }.sorted { $0.year > $1.year }

                logEvent(Event.CalendarScreen.reminderCount.rawValue, parameter: ["count": self.reminderSections.flatMap { $0.reminders }.count])
                self.checkReminderSelection()
            }
        }
    }

    // MARK: - Selection

    func toggleEventSelection(year: String, index: Int) {
        guard let sectionIndex = eventSections.firstIndex(where: { $0.year == year }) else { return }
        eventSections[sectionIndex].events[index].isSelected.toggle()
        checkEventSelection()
    }

    func toggleReminderSelection(year: String, index: Int) {
        guard let sectionIndex = reminderSections.firstIndex(where: { $0.year == year }) else { return }
        reminderSections[sectionIndex].reminders[index].isSelected.toggle()
        checkReminderSelection()
    }

    func toggleSelectAll() {
        isAllSelected.toggle()

        switch currentSegment {
        case .Calendar:
            for i in 0..<eventSections.count {
                for j in 0..<eventSections[i].events.count {
                    eventSections[i].events[j].isSelected = isAllSelected
                }
            }
        case .Reminder:
            for i in 0..<reminderSections.count {
                for j in 0..<reminderSections[i].reminders.count {
                    reminderSections[i].reminders[j].isSelected = isAllSelected
                }
            }
        }
    }

    private func checkEventSelection() {
        isAllSelected = eventSections.flatMap { $0.events }.allSatisfy { $0.isSelected }
    }

    private func checkReminderSelection() {
        isAllSelected = reminderSections.flatMap { $0.reminders }.allSatisfy { $0.isSelected }
    }

    // MARK: - Delete

    func deleteSelected() {
        isLoading = true

        switch currentSegment {
        case .Calendar:
            deleteSelectedEvents()
        case .Reminder:
            deleteSelectedReminders()
        }

        isLoading = false
    }

    private func deleteSelectedEvents() {
        var deletedCount = 0

        for section in eventSections {
            for event in section.events where event.isSelected {
                do {
                    try eventStore.remove(event.event, span: .thisEvent)
                    deletedCount += 1
                } catch {
                    print("Error deleting event: \(error)")
                }
            }
        }

        logEvent(Event.CalendarScreen.eventDeleted.rawValue, parameter: ["count": deletedCount])

        // Refresh data
        let remaining = eventSections.flatMap { $0.events }.filter { !$0.isSelected }
        let grouped = Dictionary(grouping: remaining) { $0.event.year }
        eventSections = grouped.map { year, events in
            EventSection(year: year, events: events.sorted { $0.event.startDate > $1.event.startDate })
        }.sorted { $0.year > $1.year }

        checkEventSelection()
    }

    private func deleteSelectedReminders() {
        var deletedCount = 0

        for section in reminderSections {
            for reminder in section.reminders where reminder.isSelected {
                do {
                    try eventStore.remove(reminder.reminder, commit: true)
                    deletedCount += 1
                } catch {
                    print("Error deleting reminder: \(error)")
                }
            }
        }

        logEvent(Event.CalendarScreen.reminderDeleted.rawValue, parameter: ["count": deletedCount])

        // Refresh data
        let remaining = reminderSections.flatMap { $0.reminders }.filter { !$0.isSelected }
        let grouped = Dictionary(grouping: remaining) { $0.reminder.year }
        reminderSections = grouped.map { year, reminders in
            ReminderSection(year: year, reminders: reminders.sorted { ($0.reminder.creationDate ?? Date()) < ($1.reminder.creationDate ?? Date()) })
        }.sorted { $0.year > $1.year }

        checkReminderSelection()
    }
}

// MARK: - Models

struct EventSection {
    let year: String
    var events: [CustomEKEvent]
}

struct ReminderSection {
    let year: String
    var reminders: [CustomEKReminder]
}

#Preview {
    NavigationStack {
        CalendarView()
    }
}
