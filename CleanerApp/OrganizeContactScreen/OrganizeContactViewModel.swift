//
//  OrganicContactViewModel.swift
//  CleanerApp
//
//  Created by Manu on 20/02/24.
//

import Foundation
import Contacts
import Combine
class OrganizeContactViewModel{
    @Published var contactsCount = 0
    @Published var duplicateCount = 0
    @Published var incompleteContactsCount = 0
    
    init(){
        
        DispatchQueue.global().async {
            self.findDuplicateContactsBasedOnAll()
            self.fetchContacts()
            self.findIncompleteContacts()
        }
        
    }
    
    func findIncompleteContacts() {
        let store = CNContactStore()
        let keysToFetch = [CNContactGivenNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey]
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])

        incompleteContactsCount = 0
        do {
            try store.enumerateContacts(with: fetchRequest) { contact, _ in
                
                // Check if given name is missing
                if contact.givenName.isEmpty || contact.phoneNumbers.isEmpty ||  contact.emailAddresses.isEmpty{
                    incompleteContactsCount += 1
                }
            }
        } catch {
            print("Error fetching contacts: \(error)")
        }
    }
    
    func findDuplicateContactsBasedOnAll() {
        
        let store = CNContactStore()
        
        let request = CNContactFetchRequest(keysToFetch: [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactMiddleNameKey as CNKeyDescriptor
        ])
        
        
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
            logError(error: error as NSError)
        }
    }
    
    private func fetchContacts() {
        let store = CNContactStore()
        let request = CNContactFetchRequest(keysToFetch: [])
        contactsCount = 0
        do {
            try store.enumerateContacts(with: request) { _, _ in
                contactsCount += 1
                
            }
        } catch {
            logError(error: error as NSError)
        }
    }
}


struct CustomCNContact{
    var contact: CNContact
    var isSelected: Bool
}
