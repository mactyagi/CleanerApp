//
//  DBAsset+CoreDataProperties.swift
//  CleanerApp
//
//  Created by Manu on 03/02/24.
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
    @NSManaged public var isChecked: Bool
    @NSManaged public var mediaTypeValue: String?
    @NSManaged public var sha: String?
    @NSManaged public var size: Int64
    @NSManaged public var subGroupId: UUID?

}

extension DBAsset : Identifiable {

}
