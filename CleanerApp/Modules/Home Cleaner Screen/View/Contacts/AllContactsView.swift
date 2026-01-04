//
//  AllContactsView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI
import Contacts
import ContactsUI

struct AllContactsView: View {
    @StateObject private var viewModel: AllContactsSwiftUIViewModel
    @State private var searchText = ""
    @State private var showDeleteAlert = false

    init(contactStore: CNContactStore) {
        _viewModel = StateObject(wrappedValue: AllContactsSwiftUIViewModel(contactStore: contactStore))
    }

    var body: some View {
        ZStack {
            Color.lightBlueDarkGrey
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("Loading contacts...")
            } else if viewModel.sectionTitles.isEmpty {
                emptyStateView
            } else {
                contactsList
            }
        }
        .navigationTitle("Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Name, number, company, or email")
        .onChange(of: searchText) { newValue in
            if newValue.isEmpty {
                viewModel.resetSearch()
            } else {
                logEvent(Event.AllContactScreen.search.rawValue, parameter: nil)
                viewModel.filterContacts(searchString: newValue)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(viewModel.isSelectionMode ? (viewModel.isAllSelected ? "Deselect All" : "Select All") : "Select") {
                    if viewModel.isSelectionMode {
                        if viewModel.isAllSelected {
                            logEvent(Event.AllContactScreen.deselectAll.rawValue, parameter: nil)
                            viewModel.deselectAll()
                        } else {
                            logEvent(Event.AllContactScreen.selectAll.rawValue, parameter: nil)
                            viewModel.selectAll()
                        }
                    } else {
                        logEvent(Event.AllContactScreen.select.rawValue, parameter: nil)
                        viewModel.isSelectionMode = true
                    }
                }
                .disabled(viewModel.sectionTitles.isEmpty)
            }

            if viewModel.isSelectionMode {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.isSelectionMode = false
                        viewModel.deselectAll()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.isSelectionMode && !viewModel.selectedContacts.isEmpty {
                deleteButtonView
            }
        }
        .alert("Delete \(viewModel.selectedContacts.count) \(viewModel.selectedContacts.count == 1 ? "contact" : "contacts")?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                logEvent(Event.AllContactScreen.deletePressed.rawValue, parameter: nil)
            }
            Button("Delete", role: .destructive) {
                logEvent(Event.AllContactScreen.deleteConfirmed.rawValue, parameter: ["count": viewModel.selectedContacts.count])
                viewModel.deleteSelectedContacts()
            }
        }
        .onAppear {
            logEvent(Event.AllContactScreen.appear.rawValue, parameter: nil)
            logEvent(Event.AllContactScreen.allContactCount.rawValue, parameter: ["count": viewModel.allContacts.count])
        }
        .onDisappear {
            logEvent(Event.AllContactScreen.disAppear.rawValue, parameter: nil)
        }
    }

    // MARK: - Contacts List

    private var contactsList: some View {
        List {
            ForEach(viewModel.sectionTitles, id: \.self) { sectionTitle in
                Section {
                    if let contacts = viewModel.contactsDictionary[sectionTitle] {
                        ForEach(contacts, id: \.identifier) { contact in
                            ContactRowView(
                                contact: contact,
                                isSelectionMode: viewModel.isSelectionMode,
                                isSelected: viewModel.selectedContacts.contains(contact),
                                onTap: {
                                    handleContactTap(contact)
                                },
                                onSelect: {
                                    viewModel.toggleSelection(contact)
                                }
                            )
                        }
                    }
                } header: {
                    Text(sectionTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Contacts")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your contacts will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Delete Button

    private var deleteButtonView: some View {
        Button {
            logEvent(Event.AllContactScreen.deletePressed.rawValue, parameter: nil)
            showDeleteAlert = true
        } label: {
            Text("Delete \(viewModel.selectedContacts.count) Selected")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(20)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Helpers

    private func handleContactTap(_ contact: CNContact) {
        if viewModel.isSelectionMode {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.toggleSelection(contact)
        } else {
            // Open contact detail - using UIKit CNContactViewController
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
}

// MARK: - Contact Row View

struct ContactRowView: View {
    let contact: CNContact
    let isSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if isSelectionMode {
                Button(action: onSelect) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(contactName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if !phoneNumber.isEmpty {
                    Text(phoneNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
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
class AllContactsSwiftUIViewModel: ObservableObject {
    @Published var allContacts: [CNContact] = []
    @Published var contactsDictionary: [String: [CNContact]] = [:]
    @Published var sectionTitles: [String] = []
    @Published var selectedContacts: Set<CNContact> = []
    @Published var isSelectionMode: Bool = false
    @Published var isAllSelected: Bool = false
    @Published var isLoading: Bool = true

    let contactStore: CNContactStore

    init(contactStore: CNContactStore) {
        self.contactStore = contactStore
        fetchContacts()
    }

    private func fetchContacts() {
        isLoading = true

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            var contacts: [CNContact] = []
            let request = CNContactFetchRequest(keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])

            do {
                try self.contactStore.enumerateContacts(with: request) { contact, _ in
                    contacts.append(contact)
                }
            } catch {
                logError(error: error as NSError, VCName: "AllContactsSwiftUIViewModel", functionName: #function, line: #line)
            }

            await MainActor.run {
                self.allContacts = contacts
                self.setupContacts(contacts: contacts)
                self.isLoading = false
            }
        }
    }

    private func setupContacts(contacts: [CNContact]) {
        var sorted = contacts.sorted { $0.givenName.lowercased() < $1.givenName.lowercased() }
        var dictionary: [String: [CNContact]] = [:]

        for contact in sorted {
            var firstLetter = String(contact.givenName.prefix(1)).uppercased()
            firstLetter = firstLetter.isEmpty ? "#" : firstLetter

            if dictionary[firstLetter] != nil {
                dictionary[firstLetter]?.append(contact)
            } else {
                dictionary[firstLetter] = [contact]
            }
        }

        contactsDictionary = dictionary
        sectionTitles = dictionary.keys.sorted()
    }

    func filterContacts(searchString: String) {
        let filtered = allContacts.filter { contact in
            let fullName = "\(contact.givenName) \(contact.middleName) \(contact.familyName)".lowercased()
            let phones = contact.phoneNumbers.compactMap { $0.value.stringValue }.joined(separator: " ")

            return fullName.contains(searchString.lowercased()) || phones.contains(searchString)
        }
        setupContacts(contacts: filtered)
    }

    func resetSearch() {
        setupContacts(contacts: allContacts)
    }

    func toggleSelection(_ contact: CNContact) {
        if selectedContacts.contains(contact) {
            selectedContacts.remove(contact)
        } else {
            selectedContacts.insert(contact)
        }
        updateAllSelectedState()
        logEvent(Event.AllContactScreen.selectedCount.rawValue, parameter: nil)
    }

    func selectAll() {
        selectedContacts = Set(allContacts)
        isAllSelected = true
    }

    func deselectAll() {
        selectedContacts.removeAll()
        isAllSelected = false
    }

    private func updateAllSelectedState() {
        isAllSelected = selectedContacts.count == allContacts.count && !allContacts.isEmpty
    }

    func deleteSelectedContacts() {
        isLoading = true

        for contact in selectedContacts {
            deleteContact(contact)
        }

        selectedContacts.removeAll()
        isSelectionMode = false
        fetchContacts()
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
        AllContactsView(contactStore: CNContactStore())
    }
}
