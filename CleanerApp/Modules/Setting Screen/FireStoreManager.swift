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
    
//    func fetchFeatures() {
//        let collectionRef = db.collection(CollectionName.feature).document()
//        do{
//            let features = try collectionRef.documenet
//        }
//    }
}
