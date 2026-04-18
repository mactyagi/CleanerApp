//
//  VideoCompressViewModel.swift
//  CleanerApp
//
//  Created by manu on 08/11/23.
//

import Foundation
import Photos
import Combine
class VideoCompressViewModel : ObservableObject{
    @Published var compressVideoModel = [CompressVideoModel]()
    var totalSize:Int64 = 0
    @Published var isLoading = true
    var totalCompressSize: Int64 = 0
}

extension VideoCompressViewModel{
    func fetchData(){
        self.isLoading = true
        self.totalSize = 0
        self.totalCompressSize = 0
        DispatchQueue.global().async {
            
            var compressVideoModel: [CompressVideoModel] = []
            let phAssets = PHAsset.fetchAssets(with: .video, options: PHFetchOptions())
            let dispatchGroup = DispatchGroup()
            for index in 0 ..< phAssets.count{
                dispatchGroup.enter()
                let phAsset = phAssets[index]
                phAsset.getAVAsset { avAsset in
                    if let avAsset{
                        let compressor = LightCompressor(quality: .low, asset: avAsset)
                        if let size = phAsset.getSize(){
                            DispatchQueue.main.async {
                                self.totalSize += size
                                self.totalCompressSize += compressor.estimatedOutputSize()
                            }
                            compressVideoModel.append(CompressVideoModel(phAsset: phAsset, avAsset: avAsset, originalSize: size, compressor: compressor))
                        }
                    }
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.wait()
            DispatchQueue.main.async {
                self.isLoading = false
                self.compressVideoModel = compressVideoModel
            }
            
        }
        
    }
}




