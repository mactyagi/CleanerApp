//
//  ContactsVIewModel.swift
//  CleanerApp
//
//  Created by Manukant Tyagi on 25/05/24.
//

import Foundation
import Contacts
import Combine
import ContactsUI

// MARK: - Background Actor for Contact List Operations
actor ContactListActor {
    private let contactStore: CNContactStore

    // Minimal keys for fast list loading
    private static let listKeys: [CNKeyDescriptor] = [
        CNContactIdentifierKey as CNKeyDescriptor,
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactMiddleNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactThumbnailImageDataKey as CNKeyDescriptor,
        CNContactImageDataKey as CNKeyDescriptor
    ]

    init(contactStore: CNContactStore) {
        self.contactStore = contactStore
    }

    func fetchAllContacts() throws -> [CNContact] {
        var contacts: [CNContact] = []
        let request = CNContactFetchRequest(keysToFetch: Self.listKeys)
        try contactStore.enumerateContacts(with: request) { contact, _ in
            contacts.append(contact)
        }
        return contacts
    }

    /// Refetch a single contact with all keys for CNContactViewController
    func fetchFullContact(identifier: String) throws -> CNContact? {
        let keysToFetch = [CNContactViewController.descriptorForRequiredKeys()]
        return try contactStore.unifiedContact(withIdentifier: identifier, keysToFetch: keysToFetch)
    }
}

// MARK: - ViewModel
class AllContactsVIewModel: ObservableObject {

    @Published var allContacts: [CNContact] = []
    var contactStore: CNContactStore
    var contactsDictionary = [String: [CNContact]]()
    @Published var sectionTitles = [String]()
    @Published var selectedContacts: Set<CNContact> = []
    var isSearchActive = false
    @Published var isSelectionMode = false
    @Published var isAllSelected = false
    @Published var showLoader = false

    private let contactListActor: ContactListActor

    init(contactStore: CNContactStore) {
        self.contactStore = contactStore
        self.contactListActor = ContactListActor(contactStore: contactStore)
        fetchContacts()
    }

    private func setupContacts(contacts: [CNContact]) {
        var contacts = contacts
        sectionTitles = []
        contactsDictionary.removeAll()
       contacts.sort { $0.givenName < $1.givenName }

                // Group contacts by first letter
                for contact in contacts {
                    var firstLetter = String(contact.givenName.prefix(1)).uppercased()
                    firstLetter = firstLetter.isEmpty ? "#" : firstLetter
                    if var contactsForLetter = contactsDictionary[firstLetter] {
                        contactsForLetter.append(contact)
                        contactsDictionary[firstLetter] = contactsForLetter
                    } else {
                        contactsDictionary[firstLetter] = [contact]
                    }
                }

                // Get section titles
                sectionTitles = contactsDictionary.keys.sorted()
    }


    func setContacts() {
        setupContacts(contacts: allContacts)
    }


    
    func selectedContact(_ contact: CNContact){
        if selectedContacts.contains(contact) {
            selectedContacts.remove(contact)
        } else {
            selectedContacts.insert(contact)
        }

        if allContacts.count == selectedContacts.count{
            isAllSelected = true
        } else{
            isAllSelected = false
        }
    }

    // Alias for SwiftUI views
    func selectContact(contact: CNContact) {
        selectedContact(contact)
    }

    func selectAll() {
        for contact in allContacts{
            selectedContacts.insert(contact)
        }
        isAllSelected = true
    }

    // Alias for SwiftUI views
    func selectAllContacts() {
        selectAll()
    }

    func deselectAll() {
        selectedContacts.removeAll()
        isAllSelected = false
    }

    // Alias for SwiftUI views
    func deselectAllContacts() {
        deselectAll()
    }


   private func deleteContact(_ contact: CNContact) {
//        let contactStore = CNContactStore()
        let request = CNSaveRequest()
        let mutableContact = contact.mutableCopy() as! CNMutableContact
        request.delete(mutableContact)
        do {
            try contactStore.execute(request)
            print("Contact deleted successfully")
        } catch {
            print("Error deleting contact: \(error)")
        }
    }


    func deleteSelectedContacts() {
        showLoader = true
        for contact in selectedContacts {
            deleteContact(contact)
        }
        print("Fetching contacts.")
        fetchContacts()
        showLoader = false
        isSelectionMode = false
    }

    private func fetchContacts() {
        self.allContacts = []
        showLoader = true
        Task {
            do {
                let contacts = try await contactListActor.fetchAllContacts()
                await MainActor.run {
                    self.allContacts = contacts
                    self.setupContacts(contacts: contacts)
                    self.showLoader = false
                }
            } catch {
                await MainActor.run {
                    self.showLoader = false
                }
                print("Error fetching contacts: \(error)")
            }
        }
    }

    /// Get full contact with all keys for CNContactViewController
    func getFullContact(for contact: CNContact) async -> CNContact? {
        do {
            return try await contactListActor.fetchFullContact(identifier: contact.identifier)
        } catch {
            print("Error fetching full contact: \(error)")
            return nil
        }
    }


    func filterSectionBasedOnSearch(searchString: String) {
        let filteredContacts = allContacts.filter { contact in
            var allName = ""
            if !contact.givenName.isEmpty{
                allName += contact.givenName + " "
            }
            if !contact.middleName.isEmpty{
                allName += contact.middleName + " "
            }
            if contact.familyName.isEmpty{
                allName += contact.familyName + " "
            }
            let phoneNumber = "\(contact.phoneNumbers.compactMap { $0.value.stringValue }.joined(separator: " "))"

            return allName.lowercased().contains(searchString.lowercased()) || phoneNumber.contains(searchString)
        }

        print(filteredContacts.count)
        setupContacts(contacts: filteredContacts)
    }
}
