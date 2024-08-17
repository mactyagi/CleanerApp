//
//  CompressQualitySelectionViewModel.swift
//  CleanerApp
//
//  Created by manu on 12/11/23.
//

import Foundation
import AVFoundation
import Photos
import Combine

class CompressQualitySelectionViewModel{
    @Published var compressAsset: CompressVideoModel
    init(compressAsset: CompressVideoModel) {
        self.compressAsset = compressAsset
    }
}


extension CompressQualitySelectionViewModel{
    func optimalQualitySelected(){
        let updatedAsset = compressAsset
        updatedAsset.compressor.quality = .very_high
        compressAsset = updatedAsset
    }
    
    func MediumQualitySelected(){
        let updatedAsset = compressAsset
        compressAsset.compressor.quality = .high
        compressAsset = updatedAsset
    }
    
    func MaxQualitySelected(){
        let updatedAsset = compressAsset
        compressAsset.compressor.quality = .medium
        compressAsset = updatedAsset
    }
    
    func saveVideoToPhotosLibrary(videoURL: URL, completion: @escaping (Int64, Error?) -> Void) {
        var identifier: String = ""
        PHPhotoLibrary.shared().performChanges {
       let changeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            let newIdentifier = changeRequest?.placeholderForCreatedAsset?.localIdentifier
            identifier = newIdentifier ?? ""
        } completionHandler: { success, error in
            let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: .none)
            let size = asset.firstObject?.getSize()
            completion(size ?? 0, error)
        }
    }
}
