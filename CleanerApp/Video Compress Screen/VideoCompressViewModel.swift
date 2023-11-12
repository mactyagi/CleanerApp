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
    init(){
        fetchData()
    }
}

extension VideoCompressViewModel{
    func fetchData(){
        let phAssets = PHAsset.fetchAssets(with: .video, options: PHFetchOptions())
        for index in 0 ..< phAssets.count{
            let phAsset = phAssets[index]
            phAsset.getAVAsset { avAsset, error in
                if let error{
                    
                }else if let avAsset{
                    if let size = phAsset.getSize(){
                        self.compressVideoModel.append(CompressVideoModel(phAsset: phAsset, avAsset: avAsset, originalSize: size))
                    }
                }
            }
        }
    }
}




