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
        let dispatchGroup = DispatchGroup()
        let phAsset = getPHAsset()
        if phAsset?.mediaType == .image {
         let image = phAsset?.getImage()
            guard let cgImage = image?.cgImage, let featurePrint = getFeaturePrint(image: cgImage) else {
                logErrorString(errorString: "No Image Found", VCName: "DBAsset", functionName: #function, line: #line)
                return }
            
            self.featurePrints =  [featurePrint]
        }else if phAsset?.mediaType == .video {
            dispatchGroup.enter()
            phAsset?.getAVAsset(comp: { avAsset in
                if let avAsset {
                    self.getFeaturePrintsFromAVAsset(avAsset: avAsset) { featurePrints, error in
                        self.featurePrints = featurePrints
                        dispatchGroup.leave()
                    }
                }
            })
        }
        dispatchGroup.wait()
        return
    }
    
    private func getFeaturePrint(image: CGImage) -> VNFeaturePrintObservation?{
        let requestHandler = VNImageRequestHandler(cgImage: image)
        let request = VNGenerateImageFeaturePrintRequest()
        
        #if targetEnvironment(simulator)
            request.usesCPUOnly = true
        #endif
    
        do {
            try requestHandler.perform([request])
            if let featurePrint = request.results?.first as? VNFeaturePrintObservation {
                return featurePrint
            }
        } catch {
            logError(error: error as NSError, VCName: "DBAsset", functionName: #function, line: #line)
        }
        return nil
    }

    
    private func getFeaturePrintsFromAVAsset(avAsset: AVAsset, completion: @escaping ([VNFeaturePrintObservation]?, Error?) -> Void) {
        let duration = CMTimeGetSeconds(avAsset.duration)
        let generator = AVAssetImageGenerator(asset: avAsset)
        generator.appliesPreferredTrackTransform = true
        var videoTime = CMTimeMakeWithSeconds(0, preferredTimescale: 600)
        var arrOfTime = [NSValue]()
        let videoDuration = min(Int(duration), 10)
        
        if videoDuration == 0 {
            arrOfTime.append(NSValue(time: videoTime))
        } else {
            for index in 0..<videoDuration {
                videoTime = CMTimeMakeWithSeconds(Float64(index), preferredTimescale: 600)
                arrOfTime.append(NSValue(time: videoTime))
            }
        }
        
        var featurePrints = [VNFeaturePrintObservation]()
        
        generator.generateCGImagesAsynchronously(forTimes: arrOfTime) { time, image, secondTime, result, error in
            DispatchQueue.global(qos: .userInteractive).async {
                if let error = error {
                    // Pass the error to the completion handler
                    completion(nil, error)
                    return
                }
                
                if let image = image {
                    if let featurePrint = self.getFeaturePrint(image: image) {
                        featurePrints.append(featurePrint)
                    }
                }
                
                if videoTime == time {
                    // Call completion when all images are processed
                    DispatchQueue.main.async {
                        completion(featurePrints, nil)
                    }
                }
            }
        }
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
