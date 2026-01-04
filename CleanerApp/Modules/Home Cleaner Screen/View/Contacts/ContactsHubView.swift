//
//  ContactsHubView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI
import Contacts
import ContactsUI

struct ContactsHubView: View {
    @StateObject private var viewModel = ContactsHubViewModel()

    var body: some View {
        ZStack {
            Color.lightBlueDarkGrey
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("Loading contacts...")
            } else if !viewModel.isAuthorized {
                unauthorizedView
            } else {
                contentView
            }
        }
        .navigationTitle("Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            logEvent(Event.OrganizeContactScreen.appear.rawValue, parameter: nil)
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary Card
                summaryCard

                // Navigation Cards
                NavigationLink(destination: DuplicateContactsView(contactStore: viewModel.contactStore)) {
                    contactCard(
                        icon: "person.2.fill",
                        iconColor: .orange,
                        title: "Duplicate Contacts",
                        count: viewModel.duplicateCount,
                        subtitle: "Merge similar contacts"
                    )
                }

                NavigationLink(destination: IncompleteContactsView(contactStore: viewModel.contactStore)) {
                    contactCard(
                        icon: "person.crop.circle.badge.exclamationmark",
                        iconColor: .red,
                        title: "Incomplete Contacts",
                        count: viewModel.incompleteCount,
                        subtitle: "Missing name or phone"
                    )
                }

                NavigationLink(destination: AllContactsView(contactStore: viewModel.contactStore)) {
                    contactCard(
                        icon: "person.crop.circle",
                        iconColor: .blue,
                        title: "All Contacts",
                        count: viewModel.allContactsCount,
                        subtitle: "View and manage all"
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.allContactsCount)")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Total Contacts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "person.3.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue.opacity(0.7))
            }

            Divider()

            HStack(spacing: 20) {
                statItem(count: viewModel.duplicateCount, label: "Duplicates", color: .orange)
                statItem(count: viewModel.incompleteCount, label: "Incomplete", color: .red)
            }
        }
        .padding()
        .background(Color(uiColor: .primaryCell))
        .cornerRadius(16)
    }

    private func statItem(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Contact Card

    private func contactCard(icon: String, iconColor: Color, title: String, count: Int, subtitle: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor)
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .primaryCell))
        .cornerRadius(16)
    }

    // MARK: - Unauthorized View

    private var unauthorizedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Access to Contacts")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Access is needed to manage your contacts. Your contacts will NOT be stored or used on any of our servers.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Go to Settings") {
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
}

// MARK: - ViewModel

@MainActor
class ContactsHubViewModel: ObservableObject {
    @Published var allContactsCount: Int = 0
    @Published var duplicateCount: Int = 0
    @Published var incompleteCount: Int = 0
    @Published var isLoading: Bool = true
    @Published var isAuthorized: Bool = true

    let contactStore = CNContactStore()

    init() {
        checkAuthorizationAndLoadData()
    }

    private func checkAuthorizationAndLoadData() {
        let status = CNContactStore.authorizationStatus(for: .contacts)

        switch status {
        case .authorized:
            isAuthorized = true
            loadData()
        case .notDetermined:
            requestAccess()
        default:
            isAuthorized = false
            isLoading = false
        }
    }

    private func requestAccess() {
        Task {
            do {
                let granted = try await contactStore.requestAccess(for: .contacts)
                await MainActor.run {
                    self.isAuthorized = granted
                    if granted {
                        self.loadData()
                    } else {
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isAuthorized = false
                    self.isLoading = false
                }
            }
        }
    }

    private func loadData() {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            var allContacts: [CNContact] = []
            var duplicateDict: [String: [CNContact]] = [:]
            var incompleteContacts: [CNContact] = []

            let request = CNContactFetchRequest(keysToFetch: [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactMiddleNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor
            ])

            do {
                try self.contactStore.enumerateContacts(with: request) { contact, _ in
                    allContacts.append(contact)

                    // Check for incomplete contacts
                    if contact.givenName.isEmpty || contact.phoneNumbers.isEmpty {
                        incompleteContacts.append(contact)
                    }

                    // Build duplicate dictionary
                    let fullName = "\(contact.givenName.lowercased())\(contact.middleName.lowercased())\(contact.familyName.lowercased())"
                    if !fullName.isEmpty {
                        if duplicateDict[fullName] == nil {
                            duplicateDict[fullName] = [contact]
                        } else {
                            duplicateDict[fullName]?.append(contact)
                        }
                    }

                    for phoneNumber in contact.phoneNumbers {
                        let normalized = phoneNumber.value.stringValue.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                        if duplicateDict[normalized] == nil {
                            duplicateDict[normalized] = [contact]
                        } else {
                            duplicateDict[normalized]?.append(contact)
                        }
                    }

                    for email in contact.emailAddresses {
                        let emailStr = email.value as String
                        if duplicateDict[emailStr] == nil {
                            duplicateDict[emailStr] = [contact]
                        } else {
                            duplicateDict[emailStr]?.append(contact)
                        }
                    }
                }

                // Count duplicate groups
                var duplicateGroupCount = 0
                for (_, contacts) in duplicateDict {
                    if contacts.count > 1 {
                        duplicateGroupCount += 1
                    }
                }

                await MainActor.run {
                    self.allContactsCount = allContacts.count
                    self.incompleteCount = incompleteContacts.count
                    self.duplicateCount = duplicateGroupCount
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContactsHubView()
    }
}
