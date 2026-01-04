//
//  CalendarDesignSelector.swift
//  CleanerApp
//
//  SwiftUI Calendar View - Card Stack Style with Sort
//

import SwiftUI
import EventKit

// MARK: - Sort Order
enum CalendarSortOrder: String, CaseIterable {
    case newest = "Newest First"
    case oldest = "Oldest First"

    var icon: String {
        switch self {
        case .newest: return "arrow.down"
        case .oldest: return "arrow.up"
        }
    }
}

// MARK: - Main Calendar View (Card Stack Style)
struct CalendarDesignSelector: View {
    @StateObject private var viewModel = CalendarSwiftUIViewModel(eventStore: EKEventStore())
    @State private var showDeleteAlert = false
    @State private var selectedSegment: SegmentType = .Calendar
    @State private var sortOrder: CalendarSortOrder = .newest

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header Card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedSegment == .Calendar ? "Calendar Events" : "Reminders")
                                .font(.title2.bold())
                            Text("\(viewModel.totalSelectedCount) selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()

                        // Sort Button
                        Menu {
                            ForEach(CalendarSortOrder.allCases, id: \.self) { order in
                                Button(action: {
                                    withAnimation {
                                        sortOrder = order
                                        applySorting()
                                    }
                                }) {
                                    HStack {
                                        Text(order.rawValue)
                                        if sortOrder == order {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: sortOrder.icon)
                                Text("Sort")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(Color(uiColor: .darkBlue))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(uiColor: .darkBlue).opacity(0.1))
                            .cornerRadius(10)
                        }

                        Image(systemName: selectedSegment == .Calendar ? "calendar.circle.fill" : "bell.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(Color(uiColor: .darkBlue))
                    }

                    // Segment Pills
                    HStack(spacing: 12) {
                        ForEach([SegmentType.Calendar, SegmentType.Reminder], id: \.self) { segment in
                            Button(action: {
                                withAnimation { selectedSegment = segment }
                                viewModel.updateValueFor(segment: segment)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    applySorting()
                                }
                            }) {
                                HStack {
                                    Image(systemName: segment == .Calendar ? "calendar" : "bell.fill")
                                    Text(segment == .Calendar ? "Events" : "Reminders")
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(selectedSegment == segment ? .white : Color(uiColor: .darkBlue))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    selectedSegment == segment ?
                                    Color(uiColor: .darkBlue) :
                                    Color(uiColor: .darkBlue).opacity(0.1)
                                )
                                .cornerRadius(20)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(20)
                .padding()
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)

                // Select All Row
                SelectAllRow(viewModel: viewModel)

                // List
                if selectedSegment == .Calendar {
                    CalendarEventsList(viewModel: viewModel, accentColor: .blue)
                } else {
                    CalendarRemindersList(viewModel: viewModel, accentColor: .orange)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))

            if viewModel.totalSelectedCount > 0 {
                CalendarDeleteButton(count: viewModel.totalSelectedCount) { showDeleteAlert = true }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: viewModel.totalSelectedCount)
        .alert("Delete", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { viewModel.deleteData() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Delete \(viewModel.totalSelectedCount) item(s)? This cannot be undone.")
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
            viewModel.updateValueFor(segment: selectedSegment)
        }
    }

    private func applySorting() {
        viewModel.sortData(order: sortOrder, segment: selectedSegment)
    }
}

// MARK: - Select All Row
struct SelectAllRow: View {
    @ObservedObject var viewModel: CalendarSwiftUIViewModel

    var body: some View {
        HStack {
            Text("\(viewModel.totalSelectedCount) of \(viewModel.totalCount) selected")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Button(action: { vibrate(); viewModel.selectAndDeselectAll() }) {
                Text(viewModel.isSelectedAll ? "Deselect All" : "Select All")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.isSelectedAll ? .white : Color(uiColor: .darkBlue))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        viewModel.isSelectedAll ?
                        Color(uiColor: .darkBlue) :
                        Color(uiColor: .darkBlue).opacity(0.1)
                    )
                    .cornerRadius(20)
            }
            .disabled(viewModel.totalCount == 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

// MARK: - Events List
struct CalendarEventsList: View {
    @ObservedObject var viewModel: CalendarSwiftUIViewModel
    let accentColor: Color

    var body: some View {
        if viewModel.allEvents.isEmpty {
            CalendarEmptyView(type: .Calendar)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.allEvents.enumerated()), id: \.element.year) { sectionIdx, section in
                        SectionHeader(title: section.year)
                        VStack(spacing: 0) {
                            ForEach(Array(section.events.enumerated()), id: \.element.event.eventIdentifier) { idx, event in
                                CalendarEventRow(event: event, accentColor: accentColor) {
                                    viewModel.toggleEventSelection(section: sectionIdx, index: idx)
                                }
                                if idx < section.events.count - 1 {
                                    Divider().padding(.leading, 56)
                                }
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

// MARK: - Reminders List
struct CalendarRemindersList: View {
    @ObservedObject var viewModel: CalendarSwiftUIViewModel
    let accentColor: Color

    var body: some View {
        if viewModel.allReminder.isEmpty {
            CalendarEmptyView(type: .Reminder)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.allReminder.enumerated()), id: \.element.year) { sectionIdx, section in
                        SectionHeader(title: section.year)
                        VStack(spacing: 0) {
                            ForEach(Array(section.reminders.enumerated()), id: \.element.reminder.calendarItemIdentifier) { idx, reminder in
                                CalendarReminderRow(reminder: reminder, accentColor: accentColor) {
                                    viewModel.toggleReminderSelection(section: sectionIdx, index: idx)
                                }
                                if idx < section.reminders.count - 1 {
                                    Divider().padding(.leading, 56)
                                }
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(uiColor: .label))
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Event Row
struct CalendarEventRow: View {
    let event: CustomEKEvent
    let accentColor: Color
    let onToggle: () -> Void

    var body: some View {
        Button(action: { vibrate(); onToggle() }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            event.isSelected ?
                            LinearGradient(colors: [accentColor, accentColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color(uiColor: .systemGray4), Color(uiColor: .systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    Text(String((event.event.title ?? "?").prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(event.isSelected ? .white : .secondary)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.event.title ?? "No Title")
                        .font(.body)
                        .foregroundColor(Color(uiColor: .label))
                    Text(event.event.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                SelectPill(isSelected: event.isSelected, color: accentColor)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reminder Row
struct CalendarReminderRow: View {
    let reminder: CustomEKReminder
    let accentColor: Color
    let onToggle: () -> Void

    var body: some View {
        Button(action: { vibrate(); onToggle() }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            reminder.isSelected ?
                            LinearGradient(colors: [accentColor, accentColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color(uiColor: .systemGray4), Color(uiColor: .systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    Text(String((reminder.reminder.title ?? "?").prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(reminder.isSelected ? .white : .secondary)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.reminder.title ?? "No Title")
                        .font(.body)
                        .foregroundColor(Color(uiColor: .label))
                    if let date = reminder.reminder.creationDate {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                SelectPill(isSelected: reminder.isSelected, color: accentColor)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Select Pill
struct SelectPill: View {
    let isSelected: Bool
    let color: Color

    var body: some View {
        Text(isSelected ? "Selected" : "Select")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color : color.opacity(0.1))
            .cornerRadius(20)
    }
}

// MARK: - Empty View
struct CalendarEmptyView: View {
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
struct CalendarDeleteButton: View {
    let count: Int
    let onDelete: () -> Void

    var body: some View {
        Button(action: onDelete) {
            HStack(spacing: 10) {
                Image(systemName: "trash.fill")
                Text("Delete \(count) Item\(count == 1 ? "" : "s")")
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

// MARK: - Preview
#Preview("Calendar View") {
    NavigationView {
        CalendarDesignSelector()
    }
}
