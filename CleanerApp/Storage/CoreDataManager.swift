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
    
    lazy var persistentContainer : NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CleanerApp")
        container.loadPersistentStores { storeDescription, error in
            if let error =  error as NSError?{
                fatalError("unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    
    // MARK: - Core Data Saving support
    func saveContext(context: NSManagedObjectContext?) {
        guard let context else { return }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    
    
    func fetchCustomAssets(context: NSManagedObjectContext, mediaType: PHAssetCustomMediaType?, groupType: PHAssetGroupType?, shoudHaveSHA: Bool?, shouldHaveFeaturePrint: Bool?, exceptGroupType: PHAssetGroupType? = nil) -> [CustomAsset]{
        context.performAndWait {
            let fetchRequest = CustomAsset.fetchRequest()
            var predicates = [NSPredicate]()
            if let exceptGroupType{
                predicates.append(NSPredicate(format: "groupTypeValue != %@", exceptGroupType.rawValue))
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
            fetchRequest.predicate = compoundPredicate
            
            do{
                let object = try context.fetch(fetchRequest)
                return object
            }catch{
                print("Could not fetch, \(error.localizedDescription)")
            }
            return []
        }
    }
}
