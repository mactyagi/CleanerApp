//
//  MediaModel.swift
//  CleanerApp
//
//  Created by Manu on 06/01/24.
//

import Foundation
import Photos.PHAsset

enum MediaCellType{
    case similarPhoto
    case duplicatePhoto
    case otherPhoto
    case similarScreenshot
    case duplicateScreenshot
    case otherScreenshot
    
    var cell: MediaCell{
        switch self {
        case .similarPhoto:
            return MediaCell(mainTitle: "Similar", imageName: "", cellType: self, asset: [], size: "", stackShouldVertical: true)
        case .duplicatePhoto:
            return MediaCell(mainTitle: "Duplicate", imageName: "", cellType: self, asset: [], size: "", stackShouldVertical: true)
        case .otherPhoto:
            return MediaCell(mainTitle: "Other", imageName: "", cellType: self, asset: [], size: "", stackShouldVertical: true)
        case .similarScreenshot:
            return MediaCell(mainTitle: "Similar", imageName: "", cellType: self, asset: [], size: "", stackShouldVertical: true)
        case .duplicateScreenshot:
            return MediaCell(mainTitle: "Duplicate", imageName: "", cellType: self, asset: [], size: "", stackShouldVertical: true)
        case .otherScreenshot:
            return MediaCell(mainTitle: "Other", imageName: "", cellType: self, asset: [], size: "", stackShouldVertical: true)
        }
    }
}


struct MediaCell{
    var mainTitle: String
    var imageName: String
    var cellType: MediaCellType
    var count: Int = 0
    var asset: [PHAsset]
    var size: String
    var stackShouldVertical: Bool
}
