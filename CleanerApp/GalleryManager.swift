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
    
    class func deleteAssetsById(assetIds: [String], comp: @escaping(_ isComplete: Bool, _ error: Error?) -> ()){
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: assetIds, options: nil)
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets)
        } completionHandler: { isComplete, error in
            comp(isComplete, error)
        }
    }
}



class CoreDataPHAssetManager{
    static var shared = CoreDataPHAssetManager()
    
    private var totalCount: Int = 0
    private var dispatchGroup = DispatchGroup()
    private var groupFoundCount = 0 {
        didSet{
            if groupFoundCount % 10 == 0{
                postUpdate()
            }
        }
    }
    func removeSingleElementFromCoreData(){
        let context = CoreDataManager.shared.persistentContainer.newBackgroundContext()
        let data = CoreDataManager.shared.fetchDBAssets(context: context, predicate: nil)
        let dictWithGroupId = Dictionary(grouping: data, by: \.subGroupId)
        
        for (_,value) in dictWithGroupId{
            if value.count < 2{
                for asset in value{
                    asset.subGroupId = nil
                    asset.groupTypeValue = PHAssetGroupType.other.rawValue
                }
            }
        }
        CoreDataManager.shared.saveContext(context: context)
    }
   
    
    func deleteExtraPHassetsFromCoreData(){
        let context = CoreDataManager.shared.persistentContainer.newBackgroundContext()
        let data = CoreDataManager.shared.fetchDBAssets(context: context, predicate: nil)
        var dictToDelete = Dictionary(grouping: data, by: \.assetId)
        let allPhotos = PHAsset.fetchAssets(with: .none)
//        totalCount = allPhotos * 4
        let arrayToDelete = [String]()
        
        withExecutionTime(title: "all photos Count") {
            allPhotos.enumerateObjects { asset, test, count in
                if dictToDelete[asset.localIdentifier] != nil{
                    dictToDelete[asset.localIdentifier] = nil
                }
            }
        }
        print("** all photo enumuration should completed")
        
        withExecutionTime(title: "dict enum") {
            for (_, value) in dictToDelete{
                value.forEach { asset in
                    CoreDataManager.shared.deleteAsset(asset: asset)
                }
            }
        }
    }
    
    
     func startProcess(){
         postUpdate()
        let queue = DispatchQueue.global(qos: .userInteractive)
         
         queue.async {
             self.withExecutionTime(title: "delete Asset") {
                 self.deleteExtraPHassetsFromCoreData()
                 self.removeSingleElementFromCoreData()
             }
             
             
            
             self.dispatchGroup.enter()
             queue.async {
                 self.processScreenShots()
                 self.dispatchGroup.leave()
             }
                        
            self.dispatchGroup.enter()
             queue.async {
                 self.processPhotos()
                 self.dispatchGroup.leave()
             }
             
             self.dispatchGroup.wait()
             self.postUpdate()
             print("** process completed")
         }
         
         
    }
    
    
    private func processPhotos(){
        self.addNewPHAssetsTypeInCoreData(mediaType: .photo)
        
        // process duplicate before similar is ideal otherwise duplicate photos count in similar photos
        withExecutionTime(title: "process Duplicate Photos") {
            processDuplicateAssetsFor(.photo)
        }
        withExecutionTime(title: "process similar Photos") {
            processSimilarAssetsFor(.photo)
        }
        
    }
    
    private func processScreenShots(){
        self.addNewPHAssetsTypeInCoreData(mediaType: .screenshot)
        
        // process duplicate before similar is ideal otherwise duplicate photos count in similar photos
        withExecutionTime(title: "process Duplicate SS") {
            processDuplicateAssetsFor(.screenshot)
        }
        
        withExecutionTime(title: "process similar SS") {
            processSimilarAssetsFor(.screenshot)
        }
    }

    
    
    private func processDuplicateAssetsFor(_ mediaType: PHAssetCustomMediaType){
        let context = CoreDataManager.shared.persistentContainer.newBackgroundContext()
        
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
        let context = CoreDataManager.shared.persistentContainer.newBackgroundContext()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        let oldAsset = CoreDataManager.shared.fetchCustomAssets(
            context: context,
            mediaType: mediaType,
            groupType: nil,
            shoudHaveSHA: nil,
            shouldHaveFeaturePrint: nil,
            isChecked: true,
            exceptGroupType: .duplicate,
        sortDescriptor: sortDescriptor)
        
        let newAsset = CoreDataManager.shared.fetchCustomAssets(
            context: context,
            mediaType: mediaType,
            groupType: nil,
            shoudHaveSHA: nil,
            shouldHaveFeaturePrint: nil,
            isChecked: false,
            exceptGroupType: .duplicate,
        sortDescriptor: sortDescriptor)
        
        
        let allAssets = oldAsset + newAsset
        totalCount += newAsset.count
        
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
            groupFoundCount += 1
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
        let context = CoreDataManager.shared.persistentContainer.newBackgroundContext()
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
        var count = 0
        newPHAssets.forEach { asset in
            count += 1
            let size = asset.getSize() ?? 0
//            print("** adding new data in \(mediaType.rawValue) of size \(size.formatBytes()) in Core Data")
            let _ = DBAsset(assetId: asset.localIdentifier, creationDate: asset.creationDate ?? asset.modificationDate ?? Date(), featurePrints: nil, photoGroupType: .other, mediaType: mediaType, sha: nil, insertIntoManagedObjectContext: context, size: size)
            print("** \(count)")
            CoreDataManager.shared.saveContext(context: context)
        }
        
        print("hr")
    }

    private func postUpdate(){
        NotificationCenter.default.post(name: Notification.Name.updateData, object: nil, userInfo: nil)
    }
    
    private func findAndSaveDuplicateAssets(oldAsset: [DBAsset], newAsset: [DBAsset]){
        
        newAsset.forEach { $0.calculateSHA() }
        
        let allCustomAssets = oldAsset + newAsset
        let dict = Dictionary(grouping: allCustomAssets, by: \.sha)
        
        for (_, assets) in dict{
            if assets.count > 1 {
                print(" ** Duplicate found")
                groupFoundCount += 1
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
            }
//            else{
//                for asset in assets {
//                    asset.isChecked = false
//                    if asset.subGroupId == nil{
//                        asset.groupTypeValue = PHAssetGroupType.other.rawValue
////                        print("** saving in \(#function)")
//                        CoreDataManager.shared.saveContext(context: asset.managedObjectContext)
//                    }else{
//                        let _ = DBAsset(assetId: asset.assetId!, creationDate: asset.creationDate!, featurePrints: asset.featurePrints, photoGroupType: .other, mediaType: PHAssetCustomMediaType(rawValue: asset.mediaTypeValue!)!, sha: asset.sha, insertIntoManagedObjectContext: asset.managedObjectContext!, size: asset.size)
//                        CoreDataManager.shared.deleteAsset(asset: asset)
//                    }
//                }
//            }
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
    
    private func withExecutionTime(title:String, comp: () ->()){
        let startTime = DispatchTime.now()
        comp()
        let endTime = DispatchTime.now()
        let elapsedTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        print("** time taken by \(title) is \(Double(elapsedTime) / 1_000_000_000.0)sec")
    }
}

