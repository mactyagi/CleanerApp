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

class AllContactsVIewModel{
    
    @Published var allContacts: [CNContact] = []
    var contactStore: CNContactStore
    var contactsDictionary = [String: [CNContact]]()
    @Published var sectionTitles = [String]()
    @Published var selectedContacts: Set<CNContact> = []
    var isSearchActive = false
    @Published var isSelectionMode = false
    @Published var isAllSelected = false
    @Published var showLoader =  false

    init( contactStore: CNContactStore) {
        self.contactStore = contactStore
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

    func selectAll() {
        for contact in allContacts{
            selectedContacts.insert(contact)
        }
        isAllSelected = true
    }

    func deselectAll() {
        selectedContacts.removeAll()
        isAllSelected = false
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
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            let request = CNContactFetchRequest(keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
            do {
                try contactStore.enumerateContacts(with: request) { contact, _ in
                    self.allContacts.append(contact)
                }
            } catch {
                logError(error: error as NSError)
            }

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                setupContacts(contacts: allContacts)
            }
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
