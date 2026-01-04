//
//  AllContactsView.swift
//  CleanerApp
//
//  SwiftUI view for All Contacts screen
//  - Summary cards header
//  - Horizontal filter tabs with gradients
//  - Select All / Deselect All bar
//  - Select/Selected pill buttons
//  - Bottom delete button
//

import SwiftUI
import Contacts
import ContactsUI

// MARK: - All Contacts View
struct AllContactsView: View {
    @ObservedObject var viewModel: AllContactsVIewModel
    @State private var searchText = ""
    @State private var showDeleteAlert = false
    @State private var selectedContact: CNContact?
    @State private var showContactDetail = false
    @State private var selectedFilter: ACFilterType = .all

    enum ACFilterType: String, CaseIterable {
        case all = "All"
        case withPhoto = "With Photo"
        case withPhone = "With Phone"
        case withEmail = "With Email"

        var icon: String {
            switch self {
            case .all: return "person.3.fill"
            case .withPhoto: return "person.crop.circle.fill"
            case .withPhone: return "phone.fill"
            case .withEmail: return "envelope.fill"
            }
        }

        var gradientColors: [Color] {
            switch self {
            case .all: return [Color(uiColor: .darkBlue), Color(uiColor: .darkBlue).opacity(0.7)]
            case .withPhoto: return [.purple, .purple.opacity(0.7)]
            case .withPhone: return [.green, .green.opacity(0.7)]
            case .withEmail: return [.orange, .orange.opacity(0.7)]
            }
        }
    }

    private func matchesFilter(_ contact: CNContact, filter: ACFilterType) -> Bool {
        switch filter {
        case .all: return true
        case .withPhoto: return contact.imageData != nil
        case .withPhone: return !contact.phoneNumbers.isEmpty
        case .withEmail: return !contact.emailAddresses.isEmpty
        }
    }

    private var filteredContacts: [CNContact] {
        var contacts = viewModel.allContacts

        // Apply search filter
        if !searchText.isEmpty {
            contacts = contacts.filter { contact in
                let fullName = "\(contact.givenName) \(contact.familyName)".lowercased()
                let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
                return fullName.contains(searchText.lowercased()) || phone.contains(searchText)
            }
        }

        // Apply category filter
        contacts = contacts.filter { matchesFilter($0, filter: selectedFilter) }

        return contacts
    }

    private func countForFilter(_ filter: ACFilterType) -> Int {
        viewModel.allContacts.filter { matchesFilter($0, filter: filter) }.count
    }

    private var isAllFilteredSelected: Bool {
        !filteredContacts.isEmpty && filteredContacts.allSatisfy { viewModel.selectedContacts.contains($0) }
    }

    private var selectedInFilterCount: Int {
        filteredContacts.filter { viewModel.selectedContacts.contains($0) }.count
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Summary cards header
                ACSummaryCards(
                    withPhotoCount: countForFilter(.withPhoto),
                    withPhoneCount: countForFilter(.withPhone),
                    withEmailCount: countForFilter(.withEmail),
                    selectedCount: viewModel.selectedContacts.count
                )
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(Color(uiColor: .systemGroupedBackground))

                // Search bar
                ACSearchBar(text: $searchText)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                // Filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(ACFilterType.allCases, id: \.self) { filter in
                            ACFilterTab(
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
                                if viewModel.selectedContacts.contains(contact) {
                                    viewModel.selectContact(contact: contact)
                                }
                            }
                        } else {
                            // Select all in current filter
                            for contact in filteredContacts {
                                if !viewModel.selectedContacts.contains(contact) {
                                    viewModel.selectContact(contact: contact)
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
                                ACContactRow(
                                    contact: contact,
                                    isSelected: viewModel.selectedContacts.contains(contact),
                                    isLast: index == filteredContacts.count - 1,
                                    accentColor: selectedFilter.gradientColors[0],
                                    onToggle: {
                                        viewModel.selectContact(contact: contact)
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
            if !viewModel.selectedContacts.isEmpty {
                ACDeleteButton(
                    count: viewModel.selectedContacts.count,
                    onDelete: { showDeleteAlert = true }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: viewModel.selectedContacts.isEmpty)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Contacts")
        .navigationBarTitleDisplayMode(.large)
        .alert("Delete Contacts", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                viewModel.deleteSelectedContacts()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Delete \(viewModel.selectedContacts.count) contact\(viewModel.selectedContacts.count == 1 ? "" : "s")? This cannot be undone.")
        }
        .sheet(isPresented: $showContactDetail) {
            if let contact = selectedContact {
                ACContactDetailView(contact: contact)
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
    }
}

// MARK: - Summary Cards
struct ACSummaryCards: View {
    let withPhotoCount: Int
    let withPhoneCount: Int
    let withEmailCount: Int
    let selectedCount: Int

    var body: some View {
        HStack(spacing: 12) {
            ACStatCard(icon: "person.crop.circle.fill", count: withPhotoCount, label: "With Photo", color: .purple)
            ACStatCard(icon: "phone.fill", count: withPhoneCount, label: "With Phone", color: .green)
            ACStatCard(icon: "envelope.fill", count: withEmailCount, label: "With Email", color: .orange)
        }
    }
}

struct ACStatCard: View {
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Search Bar
struct ACSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(uiColor: .secondaryLabel))

            TextField("Search contacts...", text: $text)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Filter Tab
struct ACFilterTab: View {
    let filter: AllContactsView.ACFilterType
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

// MARK: - Contact Row with Select/Selected Pills
struct ACContactRow: View {
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
        return result.isEmpty ? "#" : result
    }

    private var displayName: String {
        let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? contact.phoneNumbers.first?.value.stringValue ?? "No Name" : name
    }

    private var phoneNumber: String {
        contact.phoneNumbers.first?.value.stringValue ?? ""
    }

    private var contactInfo: String {
        var info: [String] = []
        if contact.imageData != nil { info.append("Photo") }
        if !contact.phoneNumbers.isEmpty { info.append("Phone") }
        if !contact.emailAddresses.isEmpty { info.append("Email") }
        return info.isEmpty ? "Basic info only" : info.joined(separator: " | ")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    if let imageData = contact.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
                            )
                    } else {
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
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(initials)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(isSelected ? .white : Color(uiColor: .secondaryLabel))
                            )
                    }
                }
                .onTapGesture {
                    vibrate()
                    onToggle()
                }

                // Info
                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayName)
                            .font(.body)
                            .foregroundColor(Color(uiColor: .label))

                        if !phoneNumber.isEmpty {
                            Text(phoneNumber)
                                .font(.caption)
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }

                        Text(contactInfo)
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
struct ACDeleteButton: View {
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
struct ACContactDetailView: UIViewControllerRepresentable {
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
#Preview("All Contacts View") {
    NavigationView {
        AllContactsView(viewModel: AllContactsVIewModel(contactStore: CNContactStore()))
    }
}
