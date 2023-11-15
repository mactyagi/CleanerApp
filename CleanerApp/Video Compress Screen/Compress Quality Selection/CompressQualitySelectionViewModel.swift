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
        compressAsset.compressor.quality = .very_high
    }
    
    func MediumQualitySelected(){
        compressAsset.compressor.quality = .high
    }
    
    func MaxQualitySelected(){
        compressAsset.compressor.quality = .medium
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
