//
//  IncompleteContactViewModel.swift
//  CleanerApp
//
//  Created by Manu on 06/03/24.
//

import Foundation
import Contacts

class IncompleteContactViewModel{
    var inCompleteNameContacts:[CNContact] = []
    var inCompleteEmailContacts:[CNContact] = []
    var inCompletePhoneNumberContacts:[CNContact] = []
    
    func findIncompleteContacts() {
        let store = CNContactStore()
        let keysToFetch = [CNContactGivenNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey]
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])
        
        do {
            try store.enumerateContacts(with: fetchRequest) { contact, _ in
                
                // Check if given name is missing
                if contact.givenName.isEmpty{
                    inCompleteNameContacts.append(contact)
                }else if contact.phoneNumbers.isEmpty{
                    inCompletePhoneNumberContacts.append(contact)
                }else if contact.emailAddresses.isEmpty{
                    inCompleteEmailContacts.append(contact)
                }
            }
        } catch {
            print("Error fetching contacts: \(error)")
        }
    }
}
