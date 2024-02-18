//
//  CoreDataManager.swift
//  CleanerApp
//
//  Created by Manu on 21/12/23.
//

import Foundation
import CoreData

class CoreDataManager{
    static let shared = CoreDataManager()
    private init() {}
    static let customContext = shared.persistentContainer.newBackgroundContext()
    static let secondCustomContext = shared.persistentContainer.newBackgroundContext()
    static let mainContext = shared.persistentContainer.viewContext
    
    lazy var persistentContainer : NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CleanerApp")
        container.loadPersistentStores { storeDescription, error in
            if let error =  error as NSError?{
                logError(error: error)
            }
        }
        return container
    }()
    
    
    // MARK: - Core Data Saving support
    func saveContext(context: NSManagedObjectContext?) {
        guard let context else { return }
        context.performAndWait {
            if context.hasChanges {
                do {
                    try context.save()
                    print("** saved")
//
                    
                } catch {
                    let nserror = error as NSError
                    logError(error: nserror)
                }
            }else{
    //            print(" ** Already saved")
            }
        }
        
    }
    
    
    
    func fetchDBAssets(context: NSManagedObjectContext, predicate: NSPredicate? = nil, sortDescriptor: NSSortDescriptor? = nil) -> [DBAsset]{
        context.performAndWait {
            let fetchRequest = DBAsset.fetchRequest()
            fetchRequest.predicate = predicate
            if let sortDescriptor{
                fetchRequest.sortDescriptors = [sortDescriptor]
            }
            
            do{
                let object = try context.fetch(fetchRequest)
                return object
            }catch{
                print("Could not fetch, \(error.localizedDescription)")
                logError(error: error as NSError)
            }
            return []
        }
    }
    
    func fetchCustomAssets(context: NSManagedObjectContext, mediaType: PHAssetCustomMediaType?, groupType: PHAssetGroupType?, shoudHaveSHA: Bool?, shouldHaveFeaturePrint: Bool?, shouldHaveGroupId: Bool? = nil, isChecked: Bool? = nil, exceptGroupType: PHAssetGroupType? = nil, fetchLimit: Int? = nil, sortDescriptor: NSSortDescriptor? = nil ) -> [DBAsset]{
        context.performAndWait {
            let fetchRequest = DBAsset.fetchRequest()
            
            if let sortDescriptor {
                fetchRequest.sortDescriptors = [sortDescriptor]
            }
            
            
            
            if let fetchLimit{
                fetchRequest.fetchLimit = fetchLimit
            }
            var predicates = [NSPredicate]()
            if let shouldHaveGroupId{
                predicates.append(NSPredicate(format: shouldHaveGroupId ? "subGroupId != nil" : "subGroupId == nil"))
            }
            if let exceptGroupType{
                predicates.append(NSPredicate(format: "groupTypeValue != %@", exceptGroupType.rawValue))
            }
            
            if let isChecked{
                predicates.append(NSPredicate(format: "isChecked == %@", NSNumber(value: isChecked)))
            }
            
            if let mediaType{
                predicates.append(NSPredicate(format: "mediaTypeValue == %@", mediaType.rawValue))
            }
            
            if let groupType{
                predicates.append(NSPredicate(format: "groupTypeValue == %@", groupType.rawValue))
            }
            
            if let shoudHaveSHA{
                predicates.append(NSPredicate(format: shoudHaveSHA ? "sha != nil" : "sha == nil"))
            }
            
            if let shouldHaveFeaturePrint{
                predicates.append(NSPredicate(format: shouldHaveFeaturePrint ? "featurePrints != nil" : "featurePrints == nil"))
            }
            
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            return fetchDBAssets(context: context, predicate: compoundPredicate)
        }
    }
    
    func deleteAsset(asset: DBAsset){
        guard let context = asset.managedObjectContext else { return }
        context.performAndWait {
            if let assetToDlete = context.object(with: asset.objectID) as? DBAsset{
                context.delete(assetToDlete)
                do {
                    try context.save()
                    print("Object deleted successfully.")
                } catch {
                    print("Error deleting object: \(error)")
                    logError(error: error as NSError)
                }
            }
        }
    }
}
