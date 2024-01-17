//
//  CustomAsset+CoreDataProperties.swift
//  CleanerApp
//
//  Created by Manu on 28/12/23.
//
//

import Foundation
import CoreData
import Vision


extension DBAsset {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBAsset> {
        return NSFetchRequest<DBAsset>(entityName: "DBAsset")
    }

    @NSManaged public var assetId: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var featurePrints: [VNFeaturePrintObservation]?
    @NSManaged public var groupTypeValue: String?
    @NSManaged public var mediaTypeValue: String?
    @NSManaged public var size: Int64
    @NSManaged public var subGroupId: UUID?
    @NSManaged public var sha: String?

}

extension DBAsset : Identifiable {

}
