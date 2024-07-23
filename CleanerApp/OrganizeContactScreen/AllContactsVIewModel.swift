//
//  ContactsVIewModel.swift
//  CleanerApp
//
//  Created by Manukant Tyagi on 25/05/24.
//

import Foundation
import Contacts
import Combine

class AllContactsVIewModel{
    
    private var allContacts: [CNContact]
    var contactStore: CNContactStore
    var contactsDictionary = [String: [CNContact]]()
    @Published var sectionTitles = [String]()
    var selectedContacts: Set<CNContact> = []
    var isSearchActive = false
    @Published var isSelectionMode = false

    init(allContacts: [CNContact], contactStore: CNContactStore) {
        self.allContacts = allContacts
        self.contactStore = contactStore
        setupContacts(contacts: allContacts)
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
