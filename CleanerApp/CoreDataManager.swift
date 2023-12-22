//
//  CoreDataManager.swift
//  CleanerApp
//
//  Created by Manu on 21/12/23.
//

import Foundation
import CoreData

class CoreDataManager{
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
    func saveContext(context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
