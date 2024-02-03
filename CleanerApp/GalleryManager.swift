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
import CoreData


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
    
    let progress: Progress = Progress()
    
    func deleteExtraPHassetsFromCoreData(){
        let startTime = DispatchTime.now()
        let context = CoreDataManager.customContext
        let data = CoreDataManager.shared.fetchDBAssets(context: context, predicate: nil)
        var dict = Dictionary(grouping: data, by: \.assetId)
        let allPhotos = PHAsset.fetchAssets(with: .none)
        let arrayToDelete = [String]()
        allPhotos.enumerateObjects { asset, test, _ in
            if dict[asset.localIdentifier] != nil{
                dict[asset.localIdentifier] = nil
            }
        }
        
        for (_, value) in dict{
            value.forEach { asset in
                CoreDataManager.shared.deleteAsset(asset: asset)
            }
        }
        let endTime = DispatchTime.now()
        let elapsedTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        print("** time taken by \(#function) is \(Double(elapsedTime))")
    }
    
    
     func startProcess(){
         print("** delete prcess Start")
        let queue = DispatchQueue.global(qos: .userInteractive)
         
         queue.async {
             self.deleteExtraPHassetsFromCoreData()
             let context = CoreDataManager.customContext
             let count = CoreDataManager.shared.fetchDBAssets(context: context, predicate: nil).count
             print(count)
             queue.async {
                 self.processScreenShots()
             }
             queue.async {
                 self.processPhotos()
             }
         }
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
        let context = CoreDataManager.customContext
        
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
        let context = CoreDataManager.customContext
        let oldAsset = CoreDataManager.shared.fetchCustomAssets(
            context: context,
            mediaType: mediaType,
            groupType: nil,
            shoudHaveSHA: nil,
            shouldHaveFeaturePrint: nil,
            isChecked: true,
            exceptGroupType: .duplicate)
        
        let newAsset = CoreDataManager.shared.fetchCustomAssets(
            context: context,
            mediaType: mediaType,
            groupType: nil,
            shoudHaveSHA: nil,
            shouldHaveFeaturePrint: nil,
            isChecked: false,
            exceptGroupType: .duplicate)
        
        
        let allAssets = oldAsset + newAsset
        
        
        for firstIndex in oldAsset.count ..< allAssets.count {
            let firstAsset = allAssets[firstIndex]
            if firstAsset.subGroupId != nil {
                continue
            }
            if firstAsset.featurePrints?.first == nil{
                firstAsset.addFeaturePrint()
                CoreDataManager.shared.saveContext(context: context)
            }
            
            for (secondIndex,secondAsset) in allAssets.enumerated(){
                if secondAsset.featurePrints?.first == nil{
                    secondAsset.addFeaturePrint()
                    CoreDataManager.shared.saveContext(context: context)
                }
                
                if firstIndex == secondIndex {
                    continue
                }
                
                
                
                let distance = firstAsset.computeDistance(mediaType: .photo, secondCustomAsset: secondAsset)
                
                switch distance{
                    
                case 0 ... 0.40:
//                    print("** similar \(mediaType.rawValue) found")
                    processSimilarAssets(firstAsset: firstAsset, secondAsset: secondAsset, context: context)
                    
                case 0.40 ... 9:
                    if #available(iOS 17.0, *) {
                        break
                    }else{
//                        print("** similar \(mediaType.rawValue) found")
                        processSimilarAssets(firstAsset: firstAsset, secondAsset: secondAsset, context: context)
                    }
                    
                default:
                    break
                    
                }
//                print("** saving in \(#function)")
            }
            firstAsset.isChecked = true
            CoreDataManager.shared.saveContext(context: context)
        }
    }
    
    
    
    private func processSimilarAssets(firstAsset: DBAsset, secondAsset: DBAsset, context: NSManagedObjectContext){
        
        defer {
            firstAsset.groupTypeValue = PHAssetGroupType.similar.rawValue
            secondAsset.groupTypeValue = PHAssetGroupType.similar.rawValue
            firstAsset.isChecked = true
            secondAsset.isChecked = true
            CoreDataManager.shared.saveContext(context: context)
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
        let context = CoreDataManager.customContext
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
//            print("** adding new data in \(mediaType.rawValue) of size \(size.formatBytes()) in Core Data")
            return DBAsset(assetId: asset.localIdentifier, creationDate: Date(), featurePrints: nil, photoGroupType: .other, mediaType: mediaType, sha: nil, insertIntoManagedObjectContext: context, size: size)
        }
        
//        print("** saving in \(#function)")
        CoreDataManager.shared.saveContext(context: context)
    }

    
    
    private func findAndSaveDuplicateAssets(oldAsset: [DBAsset], newAsset: [DBAsset]){
        
        newAsset.forEach { $0.calculateSHA() }
        
        var allCustomAssets = oldAsset + newAsset
        let dict = Dictionary(grouping: allCustomAssets, by: \.sha)
        
        for (key, assets) in dict{
            if assets.count > 1 {
//                print(" ** Duplicate found")
                let firstElement = assets.first!
                if firstElement.mediaTypeValue == PHAssetGroupType.duplicate.rawValue{
                    for asset in assets{
                        asset.subGroupId = firstElement.subGroupId
                        asset.mediaTypeValue = firstElement.mediaTypeValue
                        asset.groupTypeValue = firstElement.groupTypeValue
                        asset.isChecked = true
//                        print("** saving in \(#function)")
                        CoreDataManager.shared.saveContext(context: asset.managedObjectContext)
                    }
                }else{
                    let newUUID = UUID()
                    for asset in assets{
                        asset.subGroupId = newUUID
                        asset.mediaTypeValue = firstElement.mediaTypeValue
                        asset.groupTypeValue = PHAssetGroupType.duplicate.rawValue
                        asset.isChecked = true
//                        print("** saving in \(#function)")
                        CoreDataManager.shared.saveContext(context: asset.managedObjectContext)
                    }
                }
            }else{
                for asset in assets {
                    asset.isChecked = false
                    if asset.subGroupId == nil{
                        asset.groupTypeValue = PHAssetGroupType.other.rawValue
//                        print("** saving in \(#function)")
                        CoreDataManager.shared.saveContext(context: asset.managedObjectContext)
                    }else{
                        let newAsset = DBAsset(assetId: asset.assetId!, creationDate: asset.creationDate!, featurePrints: asset.featurePrints, photoGroupType: .other, mediaType: PHAssetCustomMediaType(rawValue: asset.mediaTypeValue!)!, sha: asset.sha, insertIntoManagedObjectContext: asset.managedObjectContext!, size: asset.size)
                        CoreDataManager.shared.deleteAsset(asset: asset)
                    }
                    
                }
            }
        }
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

