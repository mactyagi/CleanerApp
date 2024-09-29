//
//  CustomAsset+CoreDataClass.swift
//  CleanerApp
//
//  Created by Manu on 28/12/23.
//
//

import Foundation
import CoreData
import Vision
import Photos
import UIKit
import CryptoKit

@objc(DBAsset)
public class DBAsset: NSManagedObject {

    
    convenience init(assetId: String, creationDate: Date, featurePrints: [VNFeaturePrintObservation]?, photoGroupType: PHAssetGroupType, mediaType: PHAssetCustomMediaType, sha: String?, insertIntoManagedObjectContext context: NSManagedObjectContext, size: Int64) {
        let entity = NSEntityDescription.entity(forEntityName: "DBAsset", in: context)!
        self.init(entity: entity, insertInto: context)
        self.assetId = assetId
        self.creationDate = creationDate
        self.featurePrints = featurePrints
        self.mediaTypeValue = mediaType.rawValue
        self.size = size
        self.sha = sha
        self.groupTypeValue = photoGroupType.rawValue
        self.isChecked = false
    }
    
    
    func computeDistance(mediaType: PHAssetCustomMediaType, secondCustomAsset: DBAsset) -> Float{
        guard let firstFeaturePrints = self.featurePrints, let secondFeaturePrints = secondCustomAsset.featurePrints else {return 1000}
        switch mediaType{
        case .photo, .screenshot:
            var distance: Float = -1
            guard let firstPrint = firstFeaturePrints.first else {return 100 }
            guard let secondPrint = secondCustomAsset.featurePrints?.first else { return 100}
            do{
                try firstPrint.computeDistance(&distance, to: secondPrint)
                return distance
            }catch{
                logErrorString(errorString: "error to find distance in photos and SS. \(distance)", VCName: "DBAsset", functionName: #function, line: #line)
                print("error to find distnce. \(distance)")
                return 100
            }
        case .video:
            let minCount = firstFeaturePrints.count < secondFeaturePrints.count ? firstFeaturePrints.count : secondFeaturePrints.count
            var totalDistance: Float = 0
            for index in 0 ..< minCount{
                let firstPrint = firstFeaturePrints[index]
                let secondPrint = secondFeaturePrints[index]
                var distance: Float = 0
                do{
                    try firstPrint.computeDistance(&distance, to: secondPrint)
                    totalDistance += distance
                }catch{
                    logErrorString(errorString: "error to find distance in video \(distance)", VCName: "DBAsset", functionName: #function, line: #line)
                    print("error to find distnce. \(distance)")
                }
            }
            return totalDistance / Float(minCount)
            
        case .screenRecording:
            return -1
        }
    }
}

extension DBAsset{
    
    func getPHAsset() -> PHAsset? {
        let fetchOptions = PHFetchOptions()
        guard let localIdentifier = self.assetId else { 
            logErrorString(errorString: "Identifier not found", VCName: "DBAsset", functionName: #function, line: #line)
            return nil }
        fetchOptions.predicate = NSPredicate(format: "localIdentifier = %@", localIdentifier)

        let result = PHAsset.fetchAssets(with: fetchOptions)

        if let asset = result.firstObject {
            return asset
        } else {
            print("PHAsset not found for local identifier: \(localIdentifier)")
            logErrorString(errorString: "PHAsset not found for local identifier: \(localIdentifier)", VCName: "DBAsset", functionName: #function, line: #line)
            return nil
        }
    }
    
    
    func addFeaturePrint(){
        let phAsset = getPHAsset()
        let image = phAsset?.getImage()
        guard let cgImage = image?.cgImage else { return }
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNGenerateImageFeaturePrintRequest()
        
        #if targetEnvironment(simulator)
            request.usesCPUOnly = true
        #endif
    
        do {
            try requestHandler.perform([request])
            if let featurePrint = request.results?.first as? VNFeaturePrintObservation {
                self.featurePrints =  [featurePrint]
            }
        } catch {
        }
        return
    }
    
    func calculateSHA(){
        let phAsset = getPHAsset()
        let image = phAsset?.getImage()
        guard let imageData = image?.jpegData(compressionQuality: 1) else {
                print("Error converting image to data.")
            logErrorString(errorString: "Error converting image to data.", VCName: "DBAsset", functionName: #function, line: #line)
                return
            }

            var hasher = SHA256()
            hasher.update(data: imageData)

            let hash = hasher.finalize()
        sha = hash.map { String(format: "%02hhx", $0) }.joined()
    }
}
