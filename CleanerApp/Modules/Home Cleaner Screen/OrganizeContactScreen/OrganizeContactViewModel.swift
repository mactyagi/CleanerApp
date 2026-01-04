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
class OrganizeContactViewModel: ObservableObject {
    @Published var allContacts: [CNContact] = []
    @Published var duplicateCount = 0
    @Published var incompleteContactsCount = 0
    @Published var incompleteContacts: [CNContact] = []
    var contactStore: CNContactStore

    init(contactStore: CNContactStore){
        self.contactStore = contactStore
    }

    
    func getData() {
        DispatchQueue.global().async {
            self.findDuplicateContactsBasedOnAll()
            self.fetchContacts()
            self.findIncompleteContacts()
        }
    }

    func findIncompleteContacts() {
        incompleteContacts = []

        let fetchRequest = CNContactFetchRequest(keysToFetch: [CNContactViewController.descriptorForRequiredKeys()] /*keysToFetch as [CNKeyDescriptor]*/)

        incompleteContactsCount = 0
        do {
            try contactStore.enumerateContacts(with: fetchRequest) { contact, _ in
                
                // Check if given name is missing
                if contact.givenName.isEmpty || contact.phoneNumbers.isEmpty{
                    incompleteContacts.append(contact)
                    incompleteContactsCount += 1
                }
            }
        } catch {
            print("Error fetching contacts: \(error)")
        }
    }
    
    func findDuplicateContactsBasedOnAll() {
        
        let store = CNContactStore()
        
//        let request = CNContactFetchRequest(keysToFetch: [
//            CNContactGivenNameKey as CNKeyDescriptor,
//            CNContactFamilyNameKey as CNKeyDescriptor,
//            CNContactEmailAddressesKey as CNKeyDescriptor,
//            CNContactPhoneNumbersKey as CNKeyDescriptor,
//            CNContactMiddleNameKey as CNKeyDescriptor
//        ])

        let request = CNContactFetchRequest(keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])

        
        var contactDict = [String: [CNContact]]()
        

        do {
            try store.enumerateContacts(with: request) { contact, _ in
                // Handle name
                let fullName = "\(contact.givenName.lowercased())\(contact.middleName.lowercased())\(contact.familyName.lowercased())"
                if !fullName.isEmpty{
                    if contactDict[fullName] == nil {
                        contactDict[fullName] = [contact]
                    } else {
                        contactDict[fullName]?.append(contact)
                    }
                }
                
                
                // Handle emails
                for emailAddress in contact.emailAddresses {
                    let email = emailAddress.value as String
                    if contactDict[email] == nil {
                        contactDict[email] = [contact]
                    } else {
                        contactDict[email]?.append(contact)
                    }
                }
                
                // Handle phone numbers
                for phoneNumber in contact.phoneNumbers {
                    let number = phoneNumber.value.stringValue
                    let normalizedNumber = number.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                    
                    if contactDict[normalizedNumber] == nil {
                        contactDict[normalizedNumber] = [contact]
                    } else {
                        contactDict[normalizedNumber]?.append(contact)
                    }
                }
            }
            
            duplicateCount = 0
            
            for (_, contacts) in contactDict {
                if contacts.count > 1 {
                    duplicateCount += 1
                }
            }
            
            
        } catch {
            logError(error: error as NSError, VCName: "OrganizeContactViewModel", functionName: #function, line: #line)
        }
    }
    
    private func fetchContacts() {
        let store = CNContactStore()
        let request = CNContactFetchRequest(keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
        allContacts = []
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                allContacts.append(contact)
            }
        } catch {
            logError(error: error as NSError ,VCName: "organizeContactViewModel", functionName: #function, line: #line)
        }
    }
}


struct CustomCNContact{
    var contact: CNContact
    var isSelected: Bool
}
