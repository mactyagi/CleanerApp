//
//  IncompleteContactViewModel.swift
//  CleanerApp
//
//  Created by Manu on 06/03/24.
//

import Foundation
import Contacts
import Combine

class IncompleteContactViewModel{
    var incompleteContacts: [CNContact]

    init(incompleteContacts: [CNContact]) {
        self.incompleteContacts = incompleteContacts
    }
    
    
    @Published var selectedContactSet: Set<CNContact> = []
   @Published var isAllSelected = false
    
    
    func selectedContactAt(index: Int){
        let contact = incompleteContacts[index]
        if selectedContactSet.contains(contact) {
            selectedContactSet.remove(contact)
        } else {
            selectedContactSet.insert(contact)
        }
        
        if incompleteContacts.count == selectedContactSet.count{
            isAllSelected = true
        } else{
            isAllSelected = false
        }
    }
    
    func selectAll() {
        for contact in incompleteContacts{
            selectedContactSet.insert(contact)
        }
        isAllSelected = true
    }

    func deselectAll() {
        selectedContactSet.removeAll()
        isAllSelected = false
    }
    
//    func findIncompleteContacts() {
//        let store = CNContactStore()
//        let keysToFetch = [CNContactGivenNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey]
//        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])
//        
//        do {
//            try store.enumerateContacts(with: fetchRequest) { contact, _ in
//                
//                // Check if given name is missing
//                if contact.givenName.isEmpty{
//                    inCompleteNameContacts.append(contact)
//                }else if contact.phoneNumbers.isEmpty{
//                    inCompletePhoneNumberContacts.append(contact)
//                }else if contact.emailAddresses.isEmpty{
//                    inCompleteEmailContacts.append(contact)
//                }
//            }
//        } catch {
//            print("Error fetching contacts: \(error)")
//        }
//    }
}
