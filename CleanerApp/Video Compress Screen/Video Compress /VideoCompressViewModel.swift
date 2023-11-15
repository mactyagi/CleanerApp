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
    init(){
        fetchData()
    }
}

extension VideoCompressViewModel{
    func fetchData(){
        totalSize = 0
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
                        self.compressVideoModel.append(CompressVideoModel(phAsset: phAsset, avAsset: avAsset, originalSize: size, compressor: compressor))
                    }
                }
            }
        }
    }
}




