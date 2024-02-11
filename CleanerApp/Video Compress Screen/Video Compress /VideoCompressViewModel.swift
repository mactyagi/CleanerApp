//
//  VideoCompressViewModel.swift
//  CleanerApp
//
//  Created by manu on 08/11/23.
//

import Foundation
import Photos
import Combine
class VideoCompressViewModel{
    @Published var compressVideoModel = [CompressVideoModel]()
    var totalSize:Int64 = 0
    @Published var isLoading = true
    var totalCompressSize: Int64 = 0
}

extension VideoCompressViewModel{
    func fetchData(){
        DispatchQueue.global().async {
            self.isLoading = true
            self.totalSize = 0
            self.totalCompressSize = 0
            var compressVideoModel: [CompressVideoModel] = []
            let phAssets = PHAsset.fetchAssets(with: .video, options: PHFetchOptions())
            let dispatchGroup = DispatchGroup()
            for index in 0 ..< phAssets.count{
                dispatchGroup.enter()
                let phAsset = phAssets[index]
                phAsset.getAVAsset { avAsset, error in
                    if let error{
                        print(error.localizedDescription)
                    }else if let avAsset{
                        let compressor = LightCompressor(quality: .very_high, asset: avAsset)
                        if let size = phAsset.getSize(){
                            self.totalSize += size
                            self.totalCompressSize += compressor.estimatedOutputSize()
                            compressVideoModel.append(CompressVideoModel(phAsset: phAsset, avAsset: avAsset, originalSize: size, compressor: compressor))
                        }
                    }
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.wait()
            self.isLoading = false
            self.compressVideoModel = compressVideoModel
        }
        
    }
}




