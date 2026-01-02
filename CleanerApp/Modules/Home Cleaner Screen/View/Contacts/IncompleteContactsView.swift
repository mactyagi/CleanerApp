//
//  IncompleteContactsView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI
import Contacts
import ContactsUI

struct IncompleteContactsView: View {
    @StateObject private var viewModel: IncompleteContactsSwiftUIViewModel
    @State private var showDeleteAlert = false

    init(contactStore: CNContactStore) {
        _viewModel = StateObject(wrappedValue: IncompleteContactsSwiftUIViewModel(contactStore: contactStore))
    }

    var body: some View {
        ZStack {
            Color.lightBlueDarkGrey
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("Finding incomplete contacts...")
            } else if viewModel.incompleteContacts.isEmpty {
                emptyStateView
            } else {
                contactsList
            }
        }
        .navigationTitle("Incomplete Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(viewModel.isAllSelected ? "Deselect All" : "Select All") {
                    if viewModel.isAllSelected {
                        logEvent(Event.IncompleteContactScreen.deselectAll.rawValue, parameter: nil)
                        viewModel.deselectAll()
                    } else {
                        logEvent(Event.IncompleteContactScreen.selectAll.rawValue, parameter: nil)
                        viewModel.selectAll()
                    }
                }
                .disabled(viewModel.incompleteContacts.isEmpty)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !viewModel.selectedContacts.isEmpty {
                deleteButtonView
            }
        }
        .alert("Delete \(viewModel.selectedContacts.count) \(viewModel.selectedContacts.count == 1 ? "contact" : "contacts")?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                logEvent(Event.IncompleteContactScreen.deleteCancel.rawValue, parameter: nil)
            }
            Button("Delete", role: .destructive) {
                logEvent(Event.IncompleteContactScreen.deleteConfirmed.rawValue, parameter: ["deleted_count": viewModel.selectedContacts.count])
                viewModel.deleteSelectedContacts()
            }
        }
        .onAppear {
            logEvent(Event.IncompleteContactScreen.appear.rawValue, parameter: nil)
            logEvent(Event.IncompleteContactScreen.count.rawValue, parameter: ["count": viewModel.incompleteContacts.count])
        }
        .onDisappear {
            logEvent(Event.IncompleteContactScreen.disappear.rawValue, parameter: nil)
        }
    }

    // MARK: - Contacts List

    private var contactsList: some View {
        List {
            ForEach(Array(viewModel.incompleteContacts.enumerated()), id: \.offset) { index, contact in
                IncompleteContactRow(
                    contact: contact,
                    isSelected: viewModel.selectedContacts.contains(contact),
                    onSelect: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.toggleSelection(at: index)
                        logEvent(Event.IncompleteContactScreen.selectedCount.rawValue, parameter: ["count": viewModel.selectedContacts.count])
                    },
                    onTap: {
                        openContactDetail(contact)
                    }
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("All Contacts Complete")
                .font(.title2)
                .fontWeight(.semibold)

            Text("No contacts are missing name or phone number")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Delete Button

    private var deleteButtonView: some View {
        Button {
            logEvent(Event.IncompleteContactScreen.deleteButtonPressed.rawValue, parameter: nil)
            showDeleteAlert = true
        } label: {
            Text("Delete \(viewModel.selectedContacts.count) Selected")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.selectedContacts.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(20)
        }
        .disabled(viewModel.selectedContacts.isEmpty)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func openContactDetail(_ contact: CNContact) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            let contactVC = CNContactViewController(for: contact)
            contactVC.allowsEditing = false
            contactVC.allowsActions = true
            let navVC = UINavigationController(rootViewController: contactVC)
            rootVC.present(navVC, animated: true)
        }
    }
}

// MARK: - Incomplete Contact Row

struct IncompleteContactRow: View {
    let contact: CNContact
    let isSelected: Bool
    let onSelect: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(contactName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            if contact.givenName.isEmpty {
                                missingBadge("Name")
                            }
                        }

                        HStack(spacing: 8) {
                            if !phoneNumber.isEmpty {
                                Text(phoneNumber)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            } else {
                                missingBadge("Phone")
                            }
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
        .padding(.vertical, 4)
    }

    private func missingBadge(_ text: String) -> some View {
        Text("Missing \(text)")
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red.opacity(0.8))
            .cornerRadius(4)
    }

    private var contactName: String {
        let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "(No Name)" : name
    }

    private var phoneNumber: String {
        contact.phoneNumbers.compactMap { $0.value.stringValue }.joined(separator: " • ")
    }
}

// MARK: - ViewModel

@MainActor
class IncompleteContactsSwiftUIViewModel: ObservableObject {
    @Published var incompleteContacts: [CNContact] = []
    @Published var selectedContacts: Set<CNContact> = []
    @Published var isAllSelected: Bool = false
    @Published var isLoading: Bool = true

    let contactStore: CNContactStore

    init(contactStore: CNContactStore) {
        self.contactStore = contactStore
        findIncompleteContacts()
    }

    private func findIncompleteContacts() {
        isLoading = true

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            var contacts: [CNContact] = []
            let request = CNContactFetchRequest(keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])

            do {
                try self.contactStore.enumerateContacts(with: request) { contact, _ in
                    // Check if name or phone is missing
                    if contact.givenName.isEmpty || contact.phoneNumbers.isEmpty {
                        contacts.append(contact)
                    }
                }
            } catch {
                print("Error fetching contacts: \(error)")
            }

            // Sort by name
            let sorted = contacts.sorted { $0.givenName.lowercased() < $1.givenName.lowercased() }

            await MainActor.run {
                self.incompleteContacts = sorted
                self.isLoading = false
            }
        }
    }

    func toggleSelection(at index: Int) {
        let contact = incompleteContacts[index]
        if selectedContacts.contains(contact) {
            selectedContacts.remove(contact)
        } else {
            selectedContacts.insert(contact)
        }
        updateAllSelectedState()
    }

    func selectAll() {
        selectedContacts = Set(incompleteContacts)
        isAllSelected = true
    }

    func deselectAll() {
        selectedContacts.removeAll()
        isAllSelected = false
    }

    private func updateAllSelectedState() {
        isAllSelected = selectedContacts.count == incompleteContacts.count && !incompleteContacts.isEmpty
    }

    func deleteSelectedContacts() {
        isLoading = true

        for contact in selectedContacts {
            deleteContact(contact)
        }

        selectedContacts.removeAll()
        findIncompleteContacts()
    }

    private func deleteContact(_ contact: CNContact) {
        let request = CNSaveRequest()
        let mutableContact = contact.mutableCopy() as! CNMutableContact
        request.delete(mutableContact)

        do {
            try contactStore.execute(request)
        } catch {
            print("Error deleting contact: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        IncompleteContactsView(contactStore: CNContactStore())
    }
}
