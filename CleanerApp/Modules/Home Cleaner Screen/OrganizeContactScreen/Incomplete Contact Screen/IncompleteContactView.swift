//
//  IncompleteContactView.swift
//  CleanerApp
//
//  SwiftUI View for Incomplete Contacts
//  Gradient Filter with Select Pills style
//

import SwiftUI
import Contacts
import ContactsUI

// MARK: - Main View
struct IncompleteContactView: View {
    @ObservedObject var viewModel: IncompleteContactViewModel
    @State private var showDeleteAlert = false
    @State private var selectedContact: CNContact?
    @State private var showContactDetail = false
    @State private var selectedFilter: ICFilterType = .all

    enum ICFilterType: String, CaseIterable {
        case all = "All"
        case missingName = "No Name"
        case missingPhone = "No Phone"
        case missingBoth = "Both"

        var icon: String {
            switch self {
            case .all: return "person.3.fill"
            case .missingName: return "person.fill.questionmark"
            case .missingPhone: return "phone.badge.plus"
            case .missingBoth: return "exclamationmark.triangle.fill"
            }
        }

        var gradientColors: [Color] {
            switch self {
            case .all: return [Color(uiColor: .darkBlue), Color(uiColor: .darkBlue).opacity(0.7)]
            case .missingName: return [.orange, .orange.opacity(0.7)]
            case .missingPhone: return [.blue, .blue.opacity(0.7)]
            case .missingBoth: return [.red, .red.opacity(0.7)]
            }
        }
    }

    private func matchesFilter(_ contact: CNContact, filter: ICFilterType) -> Bool {
        let missingName = contact.givenName.isEmpty
        let missingPhone = contact.phoneNumbers.isEmpty

        switch filter {
        case .all: return true
        case .missingName: return missingName && !missingPhone
        case .missingPhone: return missingPhone && !missingName
        case .missingBoth: return missingName && missingPhone
        }
    }

    private var filteredContacts: [CNContact] {
        viewModel.inCompleteContacts.filter { matchesFilter($0, filter: selectedFilter) }
    }

    private func countForFilter(_ filter: ICFilterType) -> Int {
        viewModel.inCompleteContacts.filter { matchesFilter($0, filter: filter) }.count
    }

    private var isAllFilteredSelected: Bool {
        !filteredContacts.isEmpty && filteredContacts.allSatisfy { viewModel.selectedContactSet.contains($0) }
    }

    private var selectedInFilterCount: Int {
        filteredContacts.filter { viewModel.selectedContactSet.contains($0) }.count
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Summary cards header
                ICSummaryCards(
                    missingNameCount: countForFilter(.missingName),
                    missingPhoneCount: countForFilter(.missingPhone),
                    missingBothCount: countForFilter(.missingBoth),
                    selectedCount: viewModel.selectedContactSet.count
                )
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(Color(uiColor: .systemGroupedBackground))

                // Filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(ICFilterType.allCases, id: \.self) { filter in
                            ICFilterTab(
                                filter: filter,
                                count: countForFilter(filter),
                                isSelected: selectedFilter == filter,
                                onTap: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedFilter = filter
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))

                // Select All / Deselect All bar
                HStack {
                    Text("\(selectedInFilterCount) of \(filteredContacts.count) selected")
                        .font(.subheadline)
                        .foregroundColor(Color(uiColor: .secondaryLabel))

                    Spacer()

                    Button(action: {
                        vibrate()
                        if isAllFilteredSelected {
                            // Deselect all in current filter
                            for contact in filteredContacts {
                                if viewModel.selectedContactSet.contains(contact),
                                   let index = viewModel.inCompleteContacts.firstIndex(of: contact) {
                                    viewModel.selectedContactAt(index: index)
                                }
                            }
                        } else {
                            // Select all in current filter
                            for contact in filteredContacts {
                                if !viewModel.selectedContactSet.contains(contact),
                                   let index = viewModel.inCompleteContacts.firstIndex(of: contact) {
                                    viewModel.selectedContactAt(index: index)
                                }
                            }
                        }
                    }) {
                        Text(isAllFilteredSelected ? "Deselect All" : "Select All")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(isAllFilteredSelected ? .white : Color(uiColor: .darkBlue))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                isAllFilteredSelected ?
                                Color(uiColor: .darkBlue) :
                                Color(uiColor: .darkBlue).opacity(0.1)
                            )
                            .cornerRadius(20)
                    }
                    .disabled(filteredContacts.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(uiColor: .systemGroupedBackground))

                // Contact list
                if filteredContacts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: selectedFilter.icon)
                            .font(.system(size: 50))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))

                        Text("No contacts in this category")
                            .font(.headline)
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: .systemGroupedBackground))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filteredContacts.enumerated()), id: \.element.identifier) { index, contact in
                                ICContactRow(
                                    contact: contact,
                                    isSelected: viewModel.selectedContactSet.contains(contact),
                                    isLast: index == filteredContacts.count - 1,
                                    accentColor: selectedFilter.gradientColors[0],
                                    onToggle: {
                                        if let idx = viewModel.inCompleteContacts.firstIndex(of: contact) {
                                            viewModel.selectedContactAt(index: idx)
                                        }
                                    },
                                    onTap: {
                                        selectedContact = contact
                                        showContactDetail = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 100)
                    }
                    .background(Color(uiColor: .systemGroupedBackground))
                }
            }

            // Delete button
            if !viewModel.selectedContactSet.isEmpty {
                ICDeleteButton(
                    count: viewModel.selectedContactSet.count,
                    onDelete: { showDeleteAlert = true }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: viewModel.selectedContactSet.isEmpty)
        .navigationTitle("Incomplete Contacts")
        .navigationBarTitleDisplayMode(.large)
        .alert("Delete Contacts", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                logEvent(Event.IncompleteContactScreen.deleteConfirmed.rawValue, parameter: ["deleted_count": viewModel.selectedContactSet.count])
                viewModel.deleteSelectedContacts()
            }
            Button("Cancel", role: .cancel) {
                logEvent(Event.IncompleteContactScreen.deleteCancel.rawValue, parameter: nil)
            }
        } message: {
            Text("Delete \(viewModel.selectedContactSet.count) contact\(viewModel.selectedContactSet.count == 1 ? "" : "s")? This cannot be undone.")
        }
        .sheet(isPresented: $showContactDetail) {
            if let contact = selectedContact {
                ICContactDetailView(contact: contact)
            }
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
            logEvent(Event.IncompleteContactScreen.appear.rawValue, parameter: nil)
        }
        .onDisappear {
            logEvent(Event.IncompleteContactScreen.disappear.rawValue, parameter: nil)
        }
    }
}

// MARK: - Summary Cards
struct ICSummaryCards: View {
    let missingNameCount: Int
    let missingPhoneCount: Int
    let missingBothCount: Int
    let selectedCount: Int

    var body: some View {
        HStack(spacing: 12) {
            ICStatCard(icon: "person.fill.questionmark", count: missingNameCount, label: "No Name", color: .orange)
            ICStatCard(icon: "phone.badge.plus", count: missingPhoneCount, label: "No Phone", color: .blue)
            ICStatCard(icon: "exclamationmark.triangle.fill", count: missingBothCount, label: "Both", color: .red)
        }
    }
}

// MARK: - Stat Card
struct ICStatCard: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(uiColor: .label))

            Text(label)
                .font(.caption2)
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Filter Tab
struct ICFilterTab: View {
    let filter: IncompleteContactView.ICFilterType
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)

                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? .white.opacity(0.3) : Color(uiColor: .systemGray5))
                    .cornerRadius(8)
            }
            .foregroundColor(isSelected ? .white : Color(uiColor: .label))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isSelected ?
                LinearGradient(colors: filter.gradientColors, startPoint: .leading, endPoint: .trailing) :
                LinearGradient(colors: [Color(uiColor: .tertiarySystemGroupedBackground), Color(uiColor: .tertiarySystemGroupedBackground)], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(20)
            .shadow(color: isSelected ? filter.gradientColors[0].opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
        }
    }
}

// MARK: - Contact Row
struct ICContactRow: View {
    let contact: CNContact
    let isSelected: Bool
    let isLast: Bool
    let accentColor: Color
    let onToggle: () -> Void
    let onTap: () -> Void

    private var initials: String {
        let first = contact.givenName.first.map(String.init) ?? ""
        let last = contact.familyName.first.map(String.init) ?? ""
        let result = (first + last).uppercased()
        return result.isEmpty ? "?" : result
    }

    private var fullName: String {
        "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
    }

    private var phoneNumber: String {
        contact.phoneNumbers.first?.value.stringValue ?? ""
    }

    private var missingInfo: String {
        var missing: [String] = []
        if contact.givenName.isEmpty { missing.append("name") }
        if contact.phoneNumbers.isEmpty { missing.append("phone") }
        return "Missing " + missing.joined(separator: " & ")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color(uiColor: .systemGray4), Color(uiColor: .systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text(initials)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isSelected ? .white : Color(uiColor: .secondaryLabel))
                }
                .frame(width: 44, height: 44)
                .onTapGesture {
                    vibrate()
                    onToggle()
                }

                // Info
                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fullName.isEmpty ? "No Name" : fullName)
                            .font(.body)
                            .foregroundColor(Color(uiColor: .label))

                        if !phoneNumber.isEmpty {
                            Text(phoneNumber)
                                .font(.caption)
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }

                        Text(missingInfo)
                            .font(.caption2)
                            .foregroundColor(accentColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                // Selection pill
                Button(action: {
                    vibrate()
                    onToggle()
                }) {
                    Text(isSelected ? "Selected" : "Select")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            isSelected ?
                            accentColor :
                            accentColor.opacity(0.1)
                        )
                        .cornerRadius(20)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)

            if !isLast {
                Divider()
                    .padding(.leading, 56)
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(isLast ? 12 : 0)
    }
}

// MARK: - Delete Button
struct ICDeleteButton: View {
    let count: Int
    let onDelete: () -> Void

    var body: some View {
        Button(action: onDelete) {
            HStack(spacing: 10) {
                Image(systemName: "trash.fill")
                Text("Delete \(count) Contact\(count == 1 ? "" : "s")")
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

// MARK: - Contact Detail View
struct ICContactDetailView: UIViewControllerRepresentable {
    let contact: CNContact

    func makeUIViewController(context: Context) -> CNContactViewController {
        let vc = CNContactViewController(for: contact)
        vc.allowsEditing = true
        vc.allowsActions = true
        return vc
    }

    func updateUIViewController(_ uiViewController: CNContactViewController, context: Context) {}
}

// MARK: - Preview
#Preview {
    NavigationView {
        IncompleteContactView(viewModel: IncompleteContactViewModel(contactStore: CNContactStore()))
    }
}
