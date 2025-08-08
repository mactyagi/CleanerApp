//
//  FireStoreManager.swift
//  CleanerApp
//
//  Created by manukant tyagi on 18/09/24.
//

import Foundation
import FirebaseFirestore

class FireStoreManager {
    
    let db = Firestore.firestore()
    
    struct CollectionName {
        static let feature = "Feature"
    }
    
    
    func addFeatureInFeatureRequest(feature: Feature, completion: @escaping (_ success: Bool) -> Void) {
        let collectionRef = db.collection(CollectionName.feature)
        do {
            let newDocRef = try collectionRef.addDocument(from: feature) { error in
                if let error {
                        print("Error storing feature: \(error)")
                    completion(false)
                }else {
                    completion(true)
                }
            }
            print("Feature stored with new document reference: \(newDocRef)")
        } catch {
            print(error)
        }
    }
    
    
    func fetchFeatures(comp: @escaping (_ features: [Feature]) -> Void ){
        let collectionRef = db.collection(CollectionName.feature)
        collectionRef.getDocuments { snapShot, error in
            
            if let error {
                logErrorString(errorString: "Error fetching features: \(error)", VCName: "FireStoreManager", functionName: #function, line: #line)
                comp([])
                return
            }
            
            guard let documents = snapShot?.documents else {
                comp([])
                return
            }
                
            do {
                let features = try documents.compactMap { document -> Feature? in
                    try document.data(as: Feature.self)
                }
                comp(features)
                print(features.count)
            }catch {
                logErrorString(errorString: "Error decoding features: \(error)", VCName: "FireStoreManager", functionName: #function, line: #line)
                comp([])
            }
        }
    }
    
    func updateFeature(feature: Feature, comp: @escaping (_ success: Bool) -> Void){
        let docRef = db.collection(CollectionName.feature).document(feature.id ?? "")
        do {
            try docRef.setData(from: feature, merge: true) { error in
                if let error = error {
                   print("Error updating user: \(error)")
                   comp(false)
                } else {
                   print("User updated successfully")
                   comp(true)
                }
            }
       } catch let error {
           print("Error encoding user: \(error)")
           comp(false)
       }
    }
}
