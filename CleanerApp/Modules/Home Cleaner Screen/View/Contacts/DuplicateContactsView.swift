//
//  DuplicateContactsView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI
import Contacts
import ContactsUI

struct DuplicateContactsView: View {
    @StateObject private var viewModel: DuplicateContactsSwiftUIViewModel
    @State private var mergeAlertIndex: Int?
    @State private var showMergeAlert = false

    init(contactStore: CNContactStore) {
        _viewModel = StateObject(wrappedValue: DuplicateContactsSwiftUIViewModel(contactStore: contactStore))
    }

    var body: some View {
        ZStack {
            Color.lightBlueDarkGrey
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("Finding duplicates...")
            } else if viewModel.duplicateGroups.isEmpty {
                emptyStateView
            } else {
                duplicatesList
            }
        }
        .navigationTitle("Duplicate Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Merge Contacts?", isPresented: $showMergeAlert) {
            Button("Cancel", role: .cancel) {
                logEvent(Event.DuplicateContactScreen.mergeCancel.rawValue, parameter: nil)
            }
            Button("Merge") {
                if let index = mergeAlertIndex {
                    let count = viewModel.duplicateGroups[index].contacts.count
                    logEvent(Event.DuplicateContactScreen.mergeConfirmed.rawValue, parameter: ["merge_count": count])
                    viewModel.mergeGroup(at: index)
                }
            }
        } message: {
            Text("Selected contacts will be merged into one. This action cannot be undone.")
        }
        .onAppear {
            logEvent(Event.DuplicateContactScreen.appear.rawValue, parameter: nil)
            logEvent(Event.DuplicateContactScreen.totalMergeItems.rawValue, parameter: ["count": viewModel.duplicateGroups.count])
        }
        .onDisappear {
            logEvent(Event.DuplicateContactScreen.disappear.rawValue, parameter: nil)
        }
    }

    // MARK: - Duplicates List

    private var duplicatesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(viewModel.duplicateGroups.enumerated()), id: \.offset) { index, group in
                    DuplicateGroupCard(
                        group: group,
                        onToggleSelection: { contactIndex in
                            viewModel.toggleContactSelection(groupIndex: index, contactIndex: contactIndex)
                        },
                        onContactTap: { contact in
                            openContactDetail(contact)
                        },
                        onMerge: {
                            mergeAlertIndex = index
                            showMergeAlert = true
                        },
                        onToggleSelectAll: {
                            viewModel.toggleSelectAll(groupIndex: index)
                        }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Duplicates Found")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your contacts are well organized!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func openContactDetail(_ contact: CNContact) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            let contactVC = CNContactViewController(for: contact)
            contactVC.allowsEditing = false
            contactVC.allowsActions = false
            let navVC = UINavigationController(rootViewController: contactVC)
            rootVC.present(navVC, animated: true)
        }
    }
}

// MARK: - Duplicate Group Card

struct DuplicateGroupCard: View {
    let group: DuplicateGroup
    let onToggleSelection: (Int) -> Void
    let onContactTap: (CNContact) -> Void
    let onMerge: () -> Void
    let onToggleSelectAll: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(group.contacts.count) Contacts")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Button(action: onToggleSelectAll) {
                    Text(group.isAllSelected ? "Deselect All" : "Select All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))

            Divider()

            // Contacts
            VStack(spacing: 0) {
                ForEach(Array(group.contacts.enumerated()), id: \.offset) { index, customContact in
                    DuplicateContactRow(
                        contact: customContact.contact,
                        isSelected: customContact.isSelected,
                        onSelect: { onToggleSelection(index) },
                        onTap: { onContactTap(customContact.contact) }
                    )

                    if index < group.contacts.count - 1 {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }

            Divider()

            // Merged Preview
            if let mergedContact = group.mergedContact {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Merged Result:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(mergedContact.givenName) \(mergedContact.familyName)")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("\(mergedContact.phoneNumbers.count) phone(s), \(mergedContact.emailAddresses.count) email(s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
            }

            // Merge Button
            Button(action: onMerge) {
                HStack {
                    Image(systemName: "arrow.triangle.merge")
                    Text("Merge Contacts")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
            }
        }
        .background(Color(uiColor: .primaryCell))
        .cornerRadius(16)
    }
}

// MARK: - Duplicate Contact Row

struct DuplicateContactRow: View {
    let contact: CNContact
    let isSelected: Bool
    let onSelect: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onSelect()
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(contactName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        if !phoneNumber.isEmpty {
                            Text(phoneNumber)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var contactName: String {
        let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "(No Name)" : name
    }

    private var phoneNumber: String {
        contact.phoneNumbers.compactMap { $0.value.stringValue }.joined(separator: " • ")
    }
}

// MARK: - Models

struct DuplicateGroup {
    var contacts: [SelectableContact]
    var mergedContact: CNMutableContact?

    var isAllSelected: Bool {
        contacts.allSatisfy { $0.isSelected }
    }
}

struct SelectableContact {
    let contact: CNContact
    var isSelected: Bool
}

// MARK: - ViewModel

@MainActor
class DuplicateContactsSwiftUIViewModel: ObservableObject {
    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var isLoading: Bool = true

    let contactStore: CNContactStore

    init(contactStore: CNContactStore) {
        self.contactStore = contactStore
        findDuplicates()
    }

    private func findDuplicates() {
        isLoading = true

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            let request = CNContactFetchRequest(keysToFetch: [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactMiddleNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactBirthdayKey as CNKeyDescriptor,
                CNContactDepartmentNameKey as CNKeyDescriptor,
                CNContactImageDataKey as CNKeyDescriptor,
                CNContactJobTitleKey as CNKeyDescriptor,
                CNContactNicknameKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactViewController.descriptorForRequiredKeys()
            ])

            var duplicateDict: [String: [CNContact]] = [:]

            do {
                try self.contactStore.enumerateContacts(with: request) { contact, _ in
                    // Group by name
                    let fullName = "\(contact.givenName.lowercased())\(contact.middleName.lowercased())\(contact.familyName.lowercased())"
                    if !fullName.isEmpty {
                        if duplicateDict[fullName] == nil {
                            duplicateDict[fullName] = [contact]
                        } else {
                            duplicateDict[fullName]?.append(contact)
                        }
                    }

                    // Group by phone
                    for phoneNumber in contact.phoneNumbers {
                        let normalized = phoneNumber.value.stringValue.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                        if duplicateDict[normalized] == nil {
                            duplicateDict[normalized] = [contact]
                        } else {
                            duplicateDict[normalized]?.append(contact)
                        }
                    }

                    // Group by email
                    for email in contact.emailAddresses {
                        let emailStr = email.value as String
                        if duplicateDict[emailStr] == nil {
                            duplicateDict[emailStr] = [contact]
                        } else {
                            duplicateDict[emailStr]?.append(contact)
                        }
                    }
                }

                var groups: [DuplicateGroup] = []

                for (_, contacts) in duplicateDict where contacts.count > 1 {
                    let selectableContacts = contacts.map { SelectableContact(contact: $0, isSelected: false) }
                    let merged = Self.mergeContacts(selectableContacts)
                    groups.append(DuplicateGroup(contacts: selectableContacts, mergedContact: merged))
                }

                await MainActor.run {
                    self.duplicateGroups = groups
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    func toggleContactSelection(groupIndex: Int, contactIndex: Int) {
        duplicateGroups[groupIndex].contacts[contactIndex].isSelected.toggle()
        updateMergedContact(at: groupIndex)
    }

    func toggleSelectAll(groupIndex: Int) {
        let isAllSelected = duplicateGroups[groupIndex].isAllSelected
        for i in 0..<duplicateGroups[groupIndex].contacts.count {
            duplicateGroups[groupIndex].contacts[i].isSelected = !isAllSelected
        }
        updateMergedContact(at: groupIndex)
    }

    private func updateMergedContact(at index: Int) {
        duplicateGroups[index].mergedContact = Self.mergeContacts(duplicateGroups[index].contacts)
    }

    func mergeGroup(at index: Int) {
        let group = duplicateGroups[index]

        // Delete selected contacts
        for selectableContact in group.contacts where selectableContact.isSelected {
            deleteContact(selectableContact.contact)
        }

        // Save merged contact
        if let mergedContact = group.mergedContact {
            saveContact(mergedContact)
        }

        // Refresh
        findDuplicates()
    }

    private nonisolated static func mergeContacts(_ contacts: [SelectableContact]) -> CNMutableContact? {
        let selectedContacts = contacts.filter { $0.isSelected }
        let toMerge = selectedContacts.isEmpty ? contacts : selectedContacts

        guard let first = toMerge.first else { return nil }

        var merged = first.contact.mutableCopy() as! CNMutableContact

        for i in 1..<toMerge.count {
            let contact = toMerge[i].contact

            // Merge phone numbers
            for number in contact.phoneNumbers {
                if !merged.phoneNumbers.contains(where: { $0.value == number.value }) {
                    merged.phoneNumbers.append(number)
                }
            }

            // Merge emails
            merged.emailAddresses += contact.emailAddresses

            // Fill missing fields
            if merged.givenName.isEmpty { merged.givenName = contact.givenName }
            if merged.middleName.isEmpty { merged.middleName = contact.middleName }
            if merged.familyName.isEmpty { merged.familyName = contact.familyName }
            if merged.birthday == nil { merged.birthday = contact.birthday }
            if merged.departmentName.isEmpty { merged.departmentName = contact.departmentName }
            if merged.imageData == nil { merged.imageData = contact.imageData }
            if merged.jobTitle.isEmpty { merged.jobTitle = contact.jobTitle }
            if merged.nickname.isEmpty { merged.nickname = contact.nickname }
            if merged.organizationName.isEmpty { merged.organizationName = contact.organizationName }
        }

        return merged
    }

    private func deleteContact(_ contact: CNContact) {
        let request = CNSaveRequest()
        request.delete(contact.mutableCopy() as! CNMutableContact)

        do {
            try contactStore.execute(request)
        } catch {
            print("Failed to delete contact: \(error)")
        }
    }

    private func saveContact(_ contact: CNMutableContact) {
        let request = CNSaveRequest()
        request.add(contact, toContainerWithIdentifier: nil)

        do {
            try contactStore.execute(request)
        } catch {
            print("Failed to save contact: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        DuplicateContactsView(contactStore: CNContactStore())
    }
}
