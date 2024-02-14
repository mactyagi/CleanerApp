//
//  MediaViewModel.swift
//  CleanerApp
//
//  Created by Manu on 06/01/24.
//

import Foundation
import Combine
import CoreData
import Photos

class MediaViewModel: NSObject{
    
    var sectionsType: [(title:String, cells: [MediaCellType])] = [
        ("Photos", [.duplicatePhoto, .similarPhoto, .otherPhoto]),
        ("Screenshots", [.duplicateScreenshot, .similarScreenshot, .otherScreenshot])
    ]
    
    @Published var dataSource: [(title: String, cells:[MediaCell])] = []
    @Published var totalFiles = 0
    @Published var totalSize:Int64 = 0
    
    @Published var updateChangeInIndexPath: [IndexPath] = []{
        didSet{
            if !updateChangeInIndexPath.isEmpty{
                updateChangeInIndexPath = []
            }
        }
    }
    
    
    
    override init() {
        super.init()
        dataSource = sectionsType.map({ tuple in
            let cells = tuple.cells.map { $0.cell }
            return (tuple.title, cells)
        })
    }
    
    
    
    
    func getPredicate(mediaType: MediaCellType) -> NSPredicate{
        var assetMediaType: PHAssetCustomMediaType = .photo
        var groupType: PHAssetGroupType = .duplicate
        
        switch mediaType {
        case .similarPhoto:
            assetMediaType = .photo
            groupType = .similar
        case .duplicatePhoto:
            assetMediaType = .photo
            groupType = .duplicate
        case .otherPhoto:
            assetMediaType = .photo
            groupType = .other
        case .similarScreenshot:
            assetMediaType = .screenshot
            groupType = .similar
        case .duplicateScreenshot:
            assetMediaType = .screenshot
            groupType = .duplicate
        case .otherScreenshot:
            assetMediaType = .screenshot
            groupType = .other
        }
        
        let mediaPredicate = NSPredicate(format: "mediaTypeValue == %@", assetMediaType.rawValue)
        let groupPredicate = NSPredicate(format: "groupTypeValue == %@", groupType.rawValue)
        let isCheckedPredicate = NSPredicate(format: "isChecked == %@", NSNumber(value: true))
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [mediaPredicate, groupPredicate, isCheckedPredicate])
        
        return compoundPredicate
    }
   
    
    
    func fetchAllMediaType(){
        for type in MediaCellType.allCases{
            let context = CoreDataManager.secondCustomContext
            let predicate = getPredicate(mediaType: type)
            let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
            let assets = CoreDataManager.shared.fetchDBAssets(context: context, predicate: predicate, sortDescriptor: sortDescriptor)
            updateCell(assets: assets, type: type)
            if CoreDataPHAssetManager.shared.status == .completed{
                setupLogEvents(count: assets.count, type: type)
            }
        }
    }
    
    func setupLogEvents(count: Int, type: MediaCellType){
        switch type {
        case .similarPhoto:
            logEvent(Event.MediaScreen.similarPhotosCount.rawValue, parameter: ["count": count])
        case .duplicatePhoto:
            logEvent(Event.MediaScreen.duplicatePhotosCount.rawValue, parameter: ["count": count])
        case .otherPhoto:
            logEvent(Event.MediaScreen.otherPhotosCount.rawValue, parameter: ["count": count])
        case .similarScreenshot:
            logEvent(Event.MediaScreen.similarScreenshotCount.rawValue, parameter: ["count": count])
        case .duplicateScreenshot:
            logEvent(Event.MediaScreen.duplicateScreenshotCount.rawValue, parameter: ["count": count])
        case .otherScreenshot:
            logEvent(Event.MediaScreen.otherScreenshotCount.rawValue, parameter: ["count": count])
        }
    }
    
    
    
    private func updateCell(assets: [DBAsset], type: MediaCellType){
        var cellAssets = [PHAsset]()
        var subId: UUID?
        let size = assets.reduce(Int64(0) ) { $0 + $1.size }
        
    outerloop: for asset in assets{
            switch type{
            case .otherPhoto, .otherScreenshot:   // append 5 photos for other
                if cellAssets.count == 5{
                    break outerloop
                }
            default:
                if cellAssets.count == 2{     // append 5 photos for duplicate and similar
                    break outerloop
                }
                
            if cellAssets.count > 0 {
                if let subId{
                        // select second asset with same subId
                        if let selectedAsset = assets.filter({ $0.subGroupId == subId }).first, let asset = selectedAsset.getPHAsset(){
                            cellAssets.append(asset)
                            break outerloop
                        }
                    }
                }
            }
        
            subId = asset.subGroupId
            if let asset = asset.getPHAsset(){
                cellAssets.append(asset)
            }
        }
        
        var totalSize: Int64 = 0
        var fileCount = 0
        for(section, tuple) in dataSource.enumerated(){
            for (row, cell) in tuple.cells.enumerated(){
                if cell.cellType == type{
                    dataSource[section].cells[row].asset = cellAssets
                    dataSource[section].cells[row].size = size
                    dataSource[section].cells[row].count = assets.count
                    updateChangeInIndexPath.append(IndexPath(row: row, section: section))
                }
                totalSize += dataSource[section].cells[row].size
                fileCount += dataSource[section].cells[row].count
            }
        }
        self.totalSize = totalSize
        self.totalFiles = fileCount
    }
}
