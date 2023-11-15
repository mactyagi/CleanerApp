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
    var totalCompressSize: Int64 = 0
}

extension VideoCompressViewModel{
    func fetchData(){
        totalSize = 0
        totalCompressSize = 0
        compressVideoModel = []
        let phAssets = PHAsset.fetchAssets(with: .video, options: PHFetchOptions())
        for index in 0 ..< phAssets.count{
            let phAsset = phAssets[index]
            phAsset.getAVAsset { avAsset, error in
                if let error{
                    print(error.localizedDescription)
                }else if let avAsset{
                    let compressor = LightCompressor(quality: .very_high, asset: avAsset)
                    if let size = phAsset.getSize(){
                        self.totalSize += size
                        self.totalCompressSize += compressor.estimatedOutputSize()
                        self.compressVideoModel.append(CompressVideoModel(phAsset: phAsset, avAsset: avAsset, originalSize: size, compressor: compressor))
                    }
                }
            }
        }
    }
}




