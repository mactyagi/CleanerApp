//
//  IncompleteContactViewModel.swift
//  CleanerApp
//
//  Created by Manu on 06/03/24.
//

import Foundation
import Contacts
import Combine
import ContactsUI

class IncompleteContactViewModel{
    @Published var inCompleteContacts: [CNContact] = []
    var contactStore: CNContactStore


    init(contactStore: CNContactStore) {
        self.contactStore = contactStore
        findIncompleteContacts()
    }
    
    
    @Published var selectedContactSet: Set<CNContact> = []
   @Published var isAllSelected = false
    @Published var showLoader =  false

    func selectedContactAt(index: Int){
        let contact = inCompleteContacts[index]
        if selectedContactSet.contains(contact) {
            selectedContactSet.remove(contact)
        } else {
            selectedContactSet.insert(contact)
        }
        
        if inCompleteContacts.count == selectedContactSet.count{
            isAllSelected = true
        } else{
            isAllSelected = false
        }
    }
    
    func selectAll() {
        for contact in inCompleteContacts{
            selectedContactSet.insert(contact)
        }
        isAllSelected = true
    }

    func deselectAll() {
        selectedContactSet.removeAll()
        isAllSelected = false
    }

    private func deleteContact(_ contact: CNContact) {
         let request = CNSaveRequest()
         let mutableContact = contact.mutableCopy() as! CNMutableContact
         request.delete(mutableContact)
         do {
             try contactStore.execute(request)
             selectedContactSet.remove(contact)
             print("Contact deleted successfully")
         } catch {
             print("Error deleting contact: \(error)")
         }
     }


     func deleteSelectedContacts() {
         showLoader = true
         for contact in selectedContactSet {
             deleteContact(contact)
         }
         findIncompleteContacts()
         showLoader = false
     }

    func findIncompleteContacts() {
        showLoader = true
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            var contacts : [CNContact] = []
            let fetchRequest = CNContactFetchRequest(keysToFetch: [CNContactViewController.descriptorForRequiredKeys()] /*keysToFetch as [CNKeyDescriptor]*/)
            do {
                try contactStore.enumerateContacts(with: fetchRequest) { contact, _ in

                    // Check if given name is missing
                    if contact.givenName.isEmpty || contact.phoneNumbers.isEmpty{
                        contacts.append(contact)
                    }
                }
            } catch {
                print("Error fetching contacts: \(error)")
            }
            inCompleteContacts = []
            inCompleteContacts = contacts.sorted(by: { contact1, contact2 in
                contact1.givenName < contact2.givenName
            })
            showLoader = false
        }

    }
}
