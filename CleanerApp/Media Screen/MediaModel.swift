//
//  MediaModel.swift
//  CleanerApp
//
//  Created by Manu on 06/01/24.
//

import Foundation
import Photos.PHAsset

enum MediaCellType: String, CaseIterable{
    case similarPhoto = "Similar Photos"
    case duplicatePhoto = "Duplicate Photos"
    case otherPhoto = "Other Photos"
    case similarScreenshot = "Similar Screenshots"
    case duplicateScreenshot = "Duplicate Screenshots"
    case otherScreenshot = "Other Screenshots"
    
    var cell: MediaCell{
        switch self {
        case .similarPhoto:
            return MediaCell(mainTitle: "Similars", imageName: "photo.on.rectangle.angled", cellType: self, asset: [], size: 0, stackShouldVertical: true)
        case .duplicatePhoto:
            return MediaCell(mainTitle: "Duplicates", imageName: "photo.fill.on.rectangle.fill", cellType: self, asset: [], size: 0, stackShouldVertical: true)
        case .otherPhoto:
            return MediaCell(mainTitle: "Others", imageName: "text.below.photo.fill", cellType: self, asset: [], size: 0, stackShouldVertical: false)
        case .similarScreenshot:
            return MediaCell(mainTitle: "Similars", imageName: "photo.on.rectangle.angled", cellType: self, asset: [], size: 0, stackShouldVertical: true)
        case .duplicateScreenshot:
            return MediaCell(mainTitle: "Duplicates", imageName: "photo.fill.on.rectangle.fill", cellType: self, asset: [], size: 0, stackShouldVertical: true)
        case .otherScreenshot:
            return MediaCell(mainTitle: "Others", imageName: "text.below.photo.fill", cellType: self, asset: [], size: 0, stackShouldVertical: false)
        }
    }
}


struct MediaCell{
    var mainTitle: String
    var imageName: String
    var cellType: MediaCellType
    var count: Int = 0
    var asset: [PHAsset]
    var size: Int64
    var stackShouldVertical: Bool
}
