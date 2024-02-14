//
//  BaseViewModel.swift
//  CleanerApp
//
//  Created by Manu on 05/01/24.
//

import Foundation
import Combine
import Photos
class BaseViewModel{
    
    var assetRows: [[DBAsset]] = []
   @Published var selectedIndexPath: Set<IndexPath> = []
    @Published var sizeLabel: String = ""
    @Published var isAllSelected = true
    var groupType: PHAssetGroupType
    var type: MediaCellType
    var predicate: NSPredicate
    init(predicate: NSPredicate, groupType: PHAssetGroupType, type: MediaCellType) {
        self.predicate = predicate
        self.groupType = groupType
        self.type = type
        fetchDBAssetFromCoreData()
    }
    
    
    func fetchDBAssetFromCoreData(){
        let context = CoreDataManager.customContext
        let dbAssets = CoreDataManager.shared.fetchDBAssets(context: context, predicate: self.predicate)
        setupCountEvents(dbAssets.count)
        var newData: [[DBAsset]] = []
        var size = dbAssets.reduce(0) { $0 + $1.size }
        sizeLabel = "Photos: \(dbAssets.count) • \(size.formatBytes())"
        let dict = Dictionary(grouping: dbAssets) { $0.subGroupId }
        for (key,value) in dict{
            newData.append(value)
        }
        assetRows = newData.sorted { $0.first?.creationDate ?? Date() < $1.first?.creationDate ?? Date() }
        selectAll()
        
        
    }
    
    func setupCountEvents(_ count: Int){
        switch type {
        case .similarPhoto:
            logEvent(Event.SimilarPhotosScreen.count.rawValue, parameter: ["count": count])
        case .duplicatePhoto:
            logEvent(Event.DuplicatePhotosScreen.count.rawValue, parameter: ["count": count])
        case .otherPhoto:
            logEvent(Event.OtherPhotosScreen.count.rawValue, parameter: ["count": count])
        case .similarScreenshot:
            logEvent(Event.SimilarScreenshotScreen.count.rawValue, parameter: ["count": count])
        case .duplicateScreenshot:
            logEvent(Event.DuplicateScreenshotScreen.count.rawValue, parameter: ["count": count])
        case .otherScreenshot:
            logEvent(Event.OtherScreenshotScreen.count.rawValue, parameter: ["count": count])
        }
    }
    
    
    func deselectAll(){
        selectedIndexPath.removeAll()
    }
    
    
    func selectAll(){
        var newSelectedIndexes: Set<IndexPath> = []
        for (index,section) in assetRows.enumerated() {
            let rowsCount = section.count
            for index2 in 0 ..< rowsCount{
                if index2 > 0{
                    let indexpath = IndexPath(row: index2, section: index)
                    newSelectedIndexes.insert(indexpath)
                }else if groupType == .other {
                    let indexpath = IndexPath(row: index2, section: index)
                    newSelectedIndexes.insert(indexpath)
                }
            }
        }
        selectedIndexPath = newSelectedIndexes
    }
    
    func checkForSelection(){
        for section in 0 ..< assetRows.count{
            let isSectionSelected = isAllSelectedAt(section: section)
            if !isSectionSelected{
                isAllSelected = false
                return
            }
        }
        isAllSelected = true
    }
    
    func isAllSelectedAt(section: Int) -> Bool{
        for index in 1 ..< assetRows[section].count{
            let currentIndexPath = IndexPath(row: index, section: section)
            if !selectedIndexPath.contains(currentIndexPath){
                return false
            }
        }
        return true
    }
    
    
    func deleteAllSelected(){
        var deleteAblePhAssetIds: [String] = []
        var deletableAssets: [DBAsset] = []
        for indexPath in selectedIndexPath {
            if let id = assetRows[indexPath.section][indexPath.row].assetId{
                deleteAblePhAssetIds.append(id)
            }
            deletableAssets.append(assetRows[indexPath.section][indexPath.row])
        }
        
        PHAssetManager.deleteAssetsById(assetIds: deleteAblePhAssetIds) { isComplete, error in
            if isComplete{
                deletableAssets.forEach { asset in
                    CoreDataManager.shared.deleteAsset(asset: asset)
                }
                CoreDataPHAssetManager.shared.removeSingleElementFromCoreData()
                self.fetchDBAssetFromCoreData()
            }
        }
    }
}


struct CustomDBAsset{
    var dbAsset: DBAsset
    var isSelected: Bool
}
