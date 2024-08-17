//
//  CompressVideoModel.swift
//  CleanerApp
//
//  Created by manu on 08/11/23.
//

import Foundation
import Photos

struct CompressVideoModel{
    var phAsset: PHAsset
    var avAsset: AVAsset
    var originalSize: Int64
    var compressor: LightCompressor
    var reduceSize: Int64{
        compressor.estimatedOutputSize()
    }
    
    init(phAsset: PHAsset, avAsset: AVAsset, originalSize: Int64, compressor: LightCompressor) {
        self.phAsset = phAsset
        self.avAsset = avAsset
        self.originalSize = originalSize
        self.compressor = compressor
    }
}
