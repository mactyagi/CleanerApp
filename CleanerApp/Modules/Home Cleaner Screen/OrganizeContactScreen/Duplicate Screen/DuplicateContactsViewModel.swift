//
//  DuplicateContactsViewModel.swift
//  CleanerApp
//
//  Created by Manu on 20/02/24.
//

import Foundation
import Contacts
import ContactsUI
typealias duplicateAndMergedContactTuple = (mergedContact: CNMutableContact?, duplicatesContacts: [CustomCNContact])

class DuplicateContactsViewModel{
    
    @Published var dataSource: [duplicateAndMergedContactTuple] = []
    var contactStore: CNContactStore
    @Published var reloadAtIndex:IndexPath?

    init(contactStore: CNContactStore){
        self.contactStore = contactStore
        DispatchQueue.global().async {
            self.findDuplicateContactsBasedOnAll()
        }
    }
    
    func findDuplicateContactsBasedOnAll() {
        
        let request = CNContactFetchRequest(keysToFetch: [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactMiddleNameKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactDepartmentNameKey as CNKeyDescriptor,
            CNContactImageDataKey as CNKeyDescriptor,
            CNContactInstantMessageAddressesKey as CNKeyDescriptor,
            CNContactJobTitleKey as CNKeyDescriptor,
            CNContactNicknameKey as CNKeyDescriptor,
            CNContactRelationsKey as CNKeyDescriptor,
//            CNContactNoteKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactViewController.descriptorForRequiredKeys()
        ])

//        let request = CNContactFetchRequest(keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])

        
        var duplicateDictionary = [String: [CNContact]]()
        

        do {
            try contactStore.enumerateContacts(with: request) { contact, _ in
                // Handle name
                let fullName = "\(contact.givenName.lowercased())\(contact.middleName.lowercased())\(contact.familyName.lowercased())"
                if !fullName.isEmpty{
                    if duplicateDictionary[fullName] == nil {
                        duplicateDictionary[fullName] = [contact]
                    } else {
                        duplicateDictionary[fullName]?.append(contact)
                    }
                }
                
                
                // Handle emails
                for emailAddress in contact.emailAddresses {
                    let email = emailAddress.value as String
                    if duplicateDictionary[email] == nil {
                        duplicateDictionary[email] = [contact]
                    } else {
                        duplicateDictionary[email]?.append(contact)
                    }
                }
                
                // Handle phone numbers
                for phoneNumber in contact.phoneNumbers {
                    let number = phoneNumber.value.stringValue
                    // Normalize phone number: remove non-digit characters
                    let normalizedNumber = number.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                    
                    if duplicateDictionary[normalizedNumber] == nil {
                        duplicateDictionary[normalizedNumber] = [contact]
                    } else {
                        duplicateDictionary[normalizedNumber]?.append(contact)
                    }
                }
            }
            

            
            var tupleArray: [duplicateAndMergedContactTuple] = []
            // Print duplicate contacts based on name
            print("Duplicate contacts based on name: )")
            for (_, contacts) in duplicateDictionary {
                var duplicateContacts = [CustomCNContact]()
                if contacts.count > 1 {
                    for contact in contacts {
                        duplicateContacts.append(CustomCNContact(contact: contact, isSelected: false))
                        print("\(contact.givenName) \(contact.familyName)")
                    }
                    let mergedContact = mergeContactBasedOnSelection(duplicateContacts: duplicateContacts)
                    tupleArray.append((mergedContact, duplicateContacts))
                }
            }

            
            dataSource = tupleArray
            reloadAtIndex = nil
            
        } catch {
            logError(error: error as NSError, VCName: "DuplicateContactsViewModel", functionName: #function, line: #line)
        }
    }
    
    func resetMergeContactAt(indexes: [Int]){
        for index in indexes {
            dataSource[index].mergedContact = mergeContactBasedOnSelection(duplicateContacts: dataSource[index].duplicatesContacts)
            reloadAtIndex = IndexPath(row: index, section: 0)
        }
    }
    
    func resetSelectionAt(index: Int, isSelectedAll: Bool){
        for contactIndex in 0 ..< dataSource[index].duplicatesContacts.count{
            dataSource[index].duplicatesContacts[contactIndex].isSelected = isSelectedAll
        }
        resetMergeContactAt(indexes: [index])
        
    }
    
    
    func deleteContact(contact: CNContact) {
        let store = CNContactStore()

        let request = CNSaveRequest()
        request.delete(contact.mutableCopy() as! CNMutableContact)

        do {
            try store.execute(request)
            print("Contact deleted successfully")
        } catch {
            print("Failed to delete contact: \(error)")
        }
    }
    
    
    func saveContact(contact: CNMutableContact) {
        let store = CNContactStore()

        let saveRequest = CNSaveRequest()
        saveRequest.add(contact, toContainerWithIdentifier: nil)

        do {
            try store.execute(saveRequest)
            print("Contact saved successfully")
        } catch {
            print("Failed to save contact: \(error)")
        }
    }
    
    func mergeAndSaveAt(indexPath: IndexPath){
        for customContact in dataSource[indexPath.row].duplicatesContacts{
            if customContact.isSelected{
                deleteContact(contact: customContact.contact)
            }
        }
        if let mergedContact = dataSource[indexPath.row].mergedContact{
            saveContact(contact: mergedContact)
        }
        
        DispatchQueue.global().async {
            self.findDuplicateContactsBasedOnAll()
        }
    }
    
    func mergeContactBasedOnSelection(duplicateContacts:[CustomCNContact]) -> CNMutableContact? {
        
        if (duplicateContacts.filter { $0.isSelected }).count == 0{
           return mergeContact(contacts: duplicateContacts)
        }else{
            let selectedContacts = duplicateContacts.filter({ $0.isSelected })
            return mergeContact(contacts: selectedContacts)
        }
    }
    
    
    func mergeContact(contacts: [CustomCNContact]) -> CNMutableContact?{
        if contacts.isEmpty{ return nil}
        var mergedContact = contacts.first!.contact.mutableCopy() as! CNMutableContact
        for index in 1 ..< contacts.count {
            let duplicateContact = contacts[index].contact
                // Merge the properties of duplicateContact into mergedContact
                mergedContact = mergeContacts(mergedContact, with: duplicateContact)
        }
        return mergedContact
    }
    
    
    func mergeContacts(_ contact1: CNMutableContact, with contact2: CNContact) -> CNMutableContact {
        // Merge properties from contact2 into contact1
        print(contact1.givenName)
        for number in contact2.phoneNumbers{
            if !contact1.phoneNumbers.contains(where: { $0.value == number.value }){
                contact1.phoneNumbers.append(number)
            }
        }

        if contact1.givenName.isEmpty{
            contact1.givenName = contact2.givenName
        }
        
        if contact1.middleName.isEmpty{
            contact1.middleName = contact2.middleName
        }
        
        if contact1.familyName.isEmpty{
            contact1.familyName = contact2.familyName
        }
        
        if contact1.birthday == nil{
            contact1.birthday = contact2.birthday
        }
        
        contact1.emailAddresses += contact2.emailAddresses
        
        
        if contact1.departmentName.isEmpty {
            contact1.departmentName = contact2.departmentName
        }
        
        if contact1.imageData == nil{
            contact1.imageData = contact2.imageData
        }
        
        contact1.instantMessageAddresses += contact2.instantMessageAddresses
        
        
        if contact1.jobTitle.isEmpty{
            contact1.jobTitle = contact2.jobTitle
        }
        
        if contact1.nickname.isEmpty{
            contact1.nickname = contact2.nickname
        }
        
        contact1.contactRelations += contact2.contactRelations
        
//        contact1.note += "\n" + contact2.note
        
        if contact1.organizationName.isEmpty{
            contact1.organizationName = contact2.organizationName
        }
        
        // Return the merged contact
        return contact1
    }
}
