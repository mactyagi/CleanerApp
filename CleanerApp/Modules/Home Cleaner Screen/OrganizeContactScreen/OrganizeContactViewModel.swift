//
//  OrganicContactViewModel.swift
//  CleanerApp
//
//  Created by Manu on 20/02/24.
//

import Foundation
import Contacts
import Combine
import ContactsUI

// MARK: - Background Actor for Contact Operations
actor ContactStoreActor {
    private let contactStore: CNContactStore

    init(contactStore: CNContactStore) {
        self.contactStore = contactStore
    }

    private static let keysToFetch: [CNKeyDescriptor] = [
        CNContactIdentifierKey as CNKeyDescriptor,
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactMiddleNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor
    ]

    func fetchAllContacts() throws -> [CNContact] {
        var contacts: [CNContact] = []
        let request = CNContactFetchRequest(keysToFetch: Self.keysToFetch)
        try contactStore.enumerateContacts(with: request) { contact, _ in
            contacts.append(contact)
        }
        return contacts
    }

    func findIncompleteContacts(from contacts: [CNContact]) -> [CNContact] {
        contacts.filter { $0.givenName.isEmpty || $0.phoneNumbers.isEmpty }
    }

    func findDuplicateCount(from contacts: [CNContact]) -> Int {
        var contactDict = [String: [CNContact]]()

        for contact in contacts {
            // Handle name
            let fullName = "\(contact.givenName.lowercased())\(contact.middleName.lowercased())\(contact.familyName.lowercased())"
            if !fullName.isEmpty {
                contactDict[fullName, default: []].append(contact)
            }

            // Handle emails
            for emailAddress in contact.emailAddresses {
                let email = emailAddress.value as String
                contactDict[email, default: []].append(contact)
            }

            // Handle phone numbers
            for phoneNumber in contact.phoneNumbers {
                let number = phoneNumber.value.stringValue
                let normalizedNumber = number.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                contactDict[normalizedNumber, default: []].append(contact)
            }
        }

        return contactDict.values.filter { $0.count > 1 }.count
    }
}

// MARK: - ViewModel
@MainActor
class OrganizeContactViewModel: ObservableObject {
    @Published var allContacts: [CNContact] = []
    @Published var duplicateCount = 0
    @Published var incompleteContactsCount = 0
    @Published var incompleteContacts: [CNContact] = []
    var contactStore: CNContactStore
    private let contactStoreActor: ContactStoreActor

    init(contactStore: CNContactStore) {
        self.contactStoreActor = ContactStoreActor(contactStore: contactStore)
        self.contactStore = contactStore
    }

    func getData() async {
        do {
            // Fetch contacts on background actor
            let contacts = try await contactStoreActor.fetchAllContacts()

            // Process on background actor (parallel)
            async let incomplete = contactStoreActor.findIncompleteContacts(from: contacts)
            async let dupCount = contactStoreActor.findDuplicateCount(from: contacts)

            let (incompleteResult, duplicateResult) = await (incomplete, dupCount)

            // Update UI on main thread (we're already @MainActor)
            self.allContacts = contacts
            self.incompleteContacts = incompleteResult
            self.incompleteContactsCount = incompleteResult.count
            self.duplicateCount = duplicateResult
        } catch {
            print("Error fetching contacts: \(error)")
        }
    }
}


struct CustomCNContact{
    var contact: CNContact
    var isSelected: Bool
}
