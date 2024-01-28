//
//  GalleryManager.swift
//  CleanerApp
//
//  Created by Manu on 27/12/23.
//

import Foundation
import Photos
import Vision
import UIKit
import CryptoKit


enum PHAssetCustomMediaType: String{
    case photo
    case screenshot
    case video
    case screenRecording
}

enum PHAssetGroupType: String{
    case similar
    case duplicate
    case other
}

class PHAssetManager{
    
    private var PHAssetType:PHAssetCustomMediaType
    
   var allAssets: PHFetchResult<PHAsset>!
    
    init(PHAssetType: PHAssetCustomMediaType) {
        self.PHAssetType = PHAssetType
        getAssets()
    }
    private func getAssets(){
            let option = PHFetchOptions()
        switch PHAssetType {
            
        case .photo:
            option.predicate = NSPredicate(
                format: "NOT ((mediaSubtype & %d) != 0)",
                PHAssetMediaSubtype.photoScreenshot.rawValue
            )
            allAssets = PHAsset.fetchAssets(with: .image, options: option)
            
        case .screenshot:
            option.predicate = NSPredicate(
                format: "(mediaSubtype & %d) != 0",
                PHAssetMediaSubtype.photoScreenshot.rawValue
            )
            allAssets = PHAsset.fetchAssets(with: .image, options: option)
            
        case .video:
            allAssets = PHAsset.fetchAssets(with: .video, options: option)
            
        case .screenRecording:
            break
        }
    }
}



class CoreDataPHAssetManager{
    static var shared = CoreDataPHAssetManager()
    func deleteExtraPHassetsFromCoreData(){
        
    }
    
     func startProcess(){
//        let queue = DispatchQueue.global(qos: .userInteractive)
//        
//        queue.async {
//            print("** start photos Process **")
//            self.processScreenShots()
//            print("** End photo process **")
//        }
//        
//        queue.async {
//            print("** start SS Process **")
//            self.processScreenShots()
//            print("** End SS process **")
//        }
         
         
         print("** start Process **")
         self.processScreenShots()
         self.processPhotos()
         
         print("** end Process **")
        
    }
    
    
    private func processPhotos(){
        addNewPHAssetsTypeInCoreData(mediaType: .photo)
        
        // process duplicate before similar is ideal otherwise duplicate photos count in similar photos
        processDuplicateAssetsFor(.photo)
        processSimilarAssetsFor(.photo)
    }
    
    private func processScreenShots(){
        addNewPHAssetsTypeInCoreData(mediaType: .screenshot)
        
        // process duplicate before similar is ideal otherwise duplicate photos count in similar photos
        processDuplicateAssetsFor(.screenshot)
        processSimilarAssetsFor(.screenshot)
    }

    
    
    private func processDuplicateAssetsFor(_ mediaType: PHAssetCustomMediaType){
        let context = CoreDataManager.shared.persistentContainer.viewContext
        
        let oldAssetForDuplicate = CoreDataManager.shared.fetchCustomAssets(
            context: context,
            mediaType: mediaType,
            groupType: nil,
            shoudHaveSHA: true,
            shouldHaveFeaturePrint: nil)
        
        let newAssetsForDuplicate = CoreDataManager.shared.fetchCustomAssets(
            context: context,
            mediaType: mediaType,
            groupType: nil,
            shoudHaveSHA: false,
            shouldHaveFeaturePrint: nil)
        
        if !newAssetsForDuplicate.isEmpty{
            findAndSaveDuplicateAssets(oldAsset: oldAssetForDuplicate, newAsset: newAssetsForDuplicate)
        }
    }
    
    
    private func processSimilarAssetsFor(_ mediaType: PHAssetCustomMediaType){
        let context = CoreDataManager.shared.persistentContainer.viewContext
        let oldAsset = CoreDataManager.shared.fetchCustomAssets(
            context: context,
            mediaType: mediaType,
            groupType: nil,
            shoudHaveSHA: nil,
            shouldHaveFeaturePrint: true,
            exceptGroupType: .duplicate)
        
        let newAsset = CoreDataManager.shared.fetchCustomAssets(
            context: context,
            mediaType: mediaType,
            groupType: nil,
            shoudHaveSHA: nil,
            shouldHaveFeaturePrint: false,
            exceptGroupType: .duplicate)
        
        
        let allAssets = oldAsset + newAsset
        
        
        for firstIndex in oldAsset.count ..< allAssets.count {
            let firstAsset = allAssets[firstIndex]
            if firstAsset.subGroupId != nil {
                continue
            }
            if firstAsset.featurePrints?.first == nil{
                firstAsset.addFeaturePrint()
            }
            
            for (secondIndex,secondAsset) in allAssets.enumerated(){
                if secondAsset.featurePrints?.first == nil{
                    secondAsset.addFeaturePrint()
                }
                
                if firstIndex == secondIndex {
                    continue
                }
                
                
                
                let distance = firstAsset.computeDistance(mediaType: .photo, secondCustomAsset: secondAsset)
                
                switch distance{
                    
                case 0 ... 0.45:
                    print("** similar \(mediaType.rawValue) found")
                    processSimilarAssets(firstAsset: firstAsset, secondAsset: secondAsset)
                    
                case 0.45 ... 9:
                    if #available(iOS 17.0, *) {
                        break
                    }else{
                        print("** similar \(mediaType.rawValue) found")
                        processSimilarAssets(firstAsset: firstAsset, secondAsset: secondAsset)
                    }
                    
                default:
                    break
                    
                }
                print("** saving in \(#function)")
                CoreDataManager.shared.saveContext(context: firstAsset.managedObjectContext)
                print("** saving in \(#function)")
                CoreDataManager.shared.saveContext(context: secondAsset.managedObjectContext)
                
            }
            
            
        }
    }
    
    
    
    private func processSimilarAssets(firstAsset: DBAsset, secondAsset: DBAsset){
        
        defer {
            firstAsset.groupTypeValue = PHAssetGroupType.similar.rawValue
            secondAsset.groupTypeValue = PHAssetGroupType.similar.rawValue
        }
        
        if let subgroupId = firstAsset.subGroupId, firstAsset.groupTypeValue != PHAssetGroupType.duplicate.rawValue{
            secondAsset.subGroupId = subgroupId
            return
        }
        
        if let subGroupId = secondAsset.subGroupId, secondAsset.groupTypeValue != PHAssetGroupType.duplicate.rawValue{
            firstAsset.subGroupId = subGroupId
            
            return
        }
        
        let subGroupId = UUID()
        firstAsset.subGroupId = subGroupId
        secondAsset.subGroupId = subGroupId
    }
    
    
    
    
    
    
    //Helper Functions
    private func addNewPHAssetsTypeInCoreData(mediaType: PHAssetCustomMediaType){
        let context = CoreDataManager.shared.persistentContainer.viewContext
        guard let phAssets = PHAssetManager(PHAssetType: mediaType).allAssets else { return }
        let savedCustomPHAssets = CoreDataManager.shared.fetchCustomAssets(
            context: context,
            mediaType: mediaType,
            groupType: nil,
            shoudHaveSHA: nil,
            shouldHaveFeaturePrint: nil
        )

        var dictOfSavedCustomPHAsset : [String: DBAsset] = [:]

        for asset in savedCustomPHAssets{
            dictOfSavedCustomPHAsset[asset.assetId!] = asset
        }

        var newPHAssets: [PHAsset] = []
        for index in 0 ..< phAssets.count {
            let phAsset = phAssets.object(at: index)
            if dictOfSavedCustomPHAsset[phAsset.localIdentifier] == nil{
                newPHAssets.append(phAsset)
            }
        }
        let newCustomPHAssets = newPHAssets.map { asset in
            let size = asset.getSize() ?? 0
            print("** adding new data in \(mediaType.rawValue) of size \(size.formatBytes()) in Core Data")
            return DBAsset(assetId: asset.localIdentifier, creationDate: Date(), featurePrints: nil, photoGroupType: .other, mediaType: mediaType, sha: nil, insertIntoManagedObjectContext: context, size: size)
        }
        
        print("** saving in \(#function)")
        CoreDataManager.shared.saveContext(context: context)
    }

    
    
    private func findAndSaveDuplicateAssets(oldAsset: [DBAsset], newAsset: [DBAsset]){
        
        newAsset.forEach { $0.calculateSHA() }
        
        var allCustomAssets = oldAsset + newAsset
        let dict = Dictionary(grouping: allCustomAssets, by: \.sha)
        
        for (key, assets) in dict{
            if assets.count > 1 {
                print(" ** Duplicate found")
                let firstElement = assets.first!
                if firstElement.mediaTypeValue == PHAssetGroupType.duplicate.rawValue{
                    for asset in assets{
                        asset.subGroupId = firstElement.subGroupId
                        asset.mediaTypeValue = firstElement.mediaTypeValue
                        asset.groupTypeValue = firstElement.groupTypeValue
                        print("** saving in \(#function)")
                        CoreDataManager.shared.saveContext(context: asset.managedObjectContext)
                    }
                }else{
                    let newUUID = UUID()
                    for asset in assets{
                        asset.subGroupId = newUUID
                        asset.mediaTypeValue = firstElement.mediaTypeValue
                        asset.groupTypeValue = PHAssetGroupType.duplicate.rawValue
                        print("** saving in \(#function)")
                        CoreDataManager.shared.saveContext(context: asset.managedObjectContext)
                    }
                }
            }else{
                for asset in assets {
                    if asset.subGroupId == nil{
                        asset.groupTypeValue = PHAssetGroupType.other.rawValue
                        print("** saving in \(#function)")
                        CoreDataManager.shared.saveContext(context: asset.managedObjectContext)
                    }else{
                        let newAsset = DBAsset(assetId: asset.assetId!, creationDate: asset.creationDate!, featurePrints: asset.featurePrints, photoGroupType: .other, mediaType: PHAssetCustomMediaType(rawValue: asset.mediaTypeValue!)!, sha: asset.sha, insertIntoManagedObjectContext: asset.managedObjectContext!, size: asset.size)
                        CoreDataManager.shared.deleteAsset(asset: asset)
                    }
                    
                }
            }
        }
        
        
        let duplicateElements = CoreDataManager.shared.fetchCustomAssets(
            context: CoreDataManager.shared.persistentContainer.viewContext,
            mediaType: .photo,
            groupType: .duplicate,
            shoudHaveSHA: nil,
            shouldHaveFeaturePrint: nil)
        
        
    }
    
    
    
    private func checkForSingleDuplicateElement(oldAsset: inout [DBAsset]){
        var toRemoveSubId: [UUID] = []
        let dict = Dictionary(grouping: oldAsset, by: \.subGroupId)
        
        for (key,value) in dict{
            if value.count <= 1{
                toRemoveSubId.append(key!)
            }
        }
    }
}






//class PhotoManager {
//    var newCustomPHAssets: [DBAsset] = []
//    var allCustomPHAssets: [DBAsset] = []
//    
//    
////    func updatePhotos(){
////        
////        guard let phAssets = PHAssetManager(PHAssetType: .photo).allAssets else { return }
////    
////        var savedCustomPHAssets = CoreDataManager.shared.fetchCustomAssets(context: CoreDataManager.shared.persistentContainer.viewContext, mediaType: .photo)
////        var dictOfSavedCustomPHAsset : [String: CustomAsset] = [:]
////        
////        for asset in savedCustomPHAssets{
////            dictOfSavedCustomPHAsset[asset.assetId!] = asset
////        }
////        
////        var newPHAssets: [PHAsset] = []
////        
////        for index in 0 ..< phAssets.count {
////            let phAsset = phAssets.object(at: index)
////            if dictOfSavedCustomPHAsset[phAsset.localIdentifier] == nil{
////                newPHAssets.append(phAsset)
////            }
////        }
////        
////        
////        newCustomPHAssets = newPHAssets.map { asset in
////            CustomAsset(assetId: asset.localIdentifier, creationDate: Date(), featurePrints: [], photoGroupType: .other, mediaType: .photo, sha: nil, insertIntoManagedObjectContext: CoreDataManager.shared.persistentContainer.viewContext, size: 0)
////        }
////        
////   
////        
////    }
//    
//    func saveNewPHAssetInCoreData(){
//        
//    }
//    
//    
//    
//    
//    
//    
//    
//    
//    // fetch Similar Photos
//    // process Duplicate Photos
//    // Process Other Photos
//    // process similar Screenshots
//    // process Duplicate Screenshots
//    //Process Other ScreenShots
//    // Process similar Videos
//    
//    
//    func getDuplicateAssets(){
//        let dict = Dictionary(grouping: allCustomPHAssets, by: \.sha)
//        for key in dict.keys{
//            if dict[key]!.count > 1 {
//                print("Duplicate found.")
//            }
//        }
//    }
//}



//struct SimilarImageManager{
//    var newPHAssets:[DBAsset]
//    var processedPHAssets:[DBAsset]
//    var allCustomPHAssets = [DBAsset]()
//    init(newPHAssets: [DBAsset], processedPHAssets: [DBAsset]) {
//        self.newPHAssets = newPHAssets
//        self.processedPHAssets = processedPHAssets
//        allCustomPHAssets =  processedPHAssets + newPHAssets
//    }
//    
//    
//    
//    func compareCustomPHAsset(){
//        var similarCount = 0
//        var duplicateCount = 0
//        outerLoop : for firstIndex in processedPHAssets.count ..< allCustomPHAssets.count {
//            let firstAsset = allCustomPHAssets[firstIndex]
//            guard let mediatype = PHAssetCustomMediaType(rawValue: firstAsset.mediaTypeValue ?? "") else { continue }
//            for secondIndex in 0 ..< allCustomPHAssets.count{
//                let secondAsset = allCustomPHAssets[secondIndex]
//                if firstIndex == secondIndex || (firstAsset.subGroupId != nil && firstAsset.subGroupId == secondAsset.subGroupId) {
//                    continue
//                }
//                
//                let distance = firstAsset.computeDistance(mediaType: mediatype, secondCustomAsset: secondAsset)
//                switch distance{
//                case 0:
//                    if firstAsset.groupTypeValue == PHAssetGroupType.similar.rawValue{
//                        continue outerLoop
//                    }
//                    if secondAsset.groupTypeValue == PHAssetGroupType.similar.rawValue{
//                        continue
//                    }
//                    duplicateCount += 1
//                    updateFeatureAssetBasedOnGroupType(groupType: .duplicate)
//                   break
//                    
//                case 0...0.62:
//                    similarCount += 1
//                    if firstAsset.groupTypeValue == PHAssetGroupType.duplicate.rawValue{
//                        continue outerLoop
//                    }
//                    if secondAsset.groupTypeValue == PHAssetGroupType.duplicate.rawValue{
//                        continue
//                    }
//
//                    updateFeatureAssetBasedOnGroupType(groupType: .similar)
//                    break
//                case 0.62 ... 9:
//                    if #available(iOS 17.0, *) {
//                        break
//                    }else{
//                        similarCount += 1
//                        if firstAsset.groupTypeValue == PHAssetGroupType.duplicate.rawValue{
//                            continue outerLoop
//                        }
//                        if secondAsset.groupTypeValue == PHAssetGroupType.duplicate.rawValue{
//                            continue
//                        }
//
//                        updateFeatureAssetBasedOnGroupType(groupType: .similar)
//                    }
//                    
//                    
//                default:
//                    break
//                }
//             
//                func updateFeatureAssetBasedOnGroupType(groupType: PHAssetGroupType){
//                    if let id = firstAsset.subGroupId{
//                        allCustomPHAssets[secondIndex].subGroupId = id
//                        allCustomPHAssets[secondIndex].groupTypeValue = groupType.rawValue
//                    }else if let id = secondAsset.subGroupId{
//                        allCustomPHAssets[firstIndex].subGroupId = id
//                        allCustomPHAssets[firstIndex].groupTypeValue = groupType.rawValue
//                    }else{
//                        let UUID = UUID()
//                        allCustomPHAssets[firstIndex].subGroupId = UUID
//                        allCustomPHAssets[secondIndex].subGroupId = UUID
//                        allCustomPHAssets[firstIndex].groupTypeValue = groupType.rawValue
//                        allCustomPHAssets[secondIndex].groupTypeValue = groupType.rawValue
//                    }
////                    CoreDataManager.shared.save(context: context)
//                }
//            }
////            progress(firstIndex + 1, allFeatureAsset.count)
//        }
//        
//        
//    }
//    
//    
//    
//    
//    
//    
//    
//}

//struct CustomAsset2 {
//
//    init(assetId: String? = nil, creationDate: Date? = nil, featurePrints: [VNFeaturePrintObservation]? = nil, groupTypeValue: String? = nil, mediaTypeValue: String? = nil, size: Int64, subGroupId: UUID? = nil, sha: String? = nil) {
//        self.assetId = assetId
//        self.creationDate = creationDate
//        self.featurePrints = featurePrints
//        self.groupTypeValue = groupTypeValue
//        self.mediaTypeValue = mediaTypeValue
//        self.size = size
//        self.subGroupId = subGroupId
//        self.sha = sha
//        self.isNew = true
//    }
//    
//    init(customAsset: DBAsset) {
//        self.assetId = customAsset.assetId
//        self.creationDate = customAsset.creationDate
//        self.featurePrints = customAsset.featurePrints
//        self.groupTypeValue = customAsset.groupTypeValue
//        self.mediaTypeValue = customAsset.mediaTypeValue
//        self.size = customAsset.size
//        self.subGroupId = customAsset.subGroupId
//        self.sha = customAsset.sha
//        self.isNew = false
//    }
//    
//    
//   var assetId: String?
//   var creationDate: Date?
//   var featurePrints: [VNFeaturePrintObservation]?
//   var groupTypeValue: String?
//   var mediaTypeValue: String?
//   var size: Int64
//   var subGroupId: UUID?
//   var sha: String?
//    var isNew: Bool
//
//}

