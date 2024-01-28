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

    
    
    private var fetchedResultsControllerForDuplicatePhotos: NSFetchedResultsController<DBAsset>?
    private var fetchedResultsControllerForSimilarPhotos: NSFetchedResultsController<DBAsset>?
    private var fetchedResultsControllerForOtherPhotos: NSFetchedResultsController<DBAsset>?
    private var fetchedResultsControllerForDuplicateSS: NSFetchedResultsController<DBAsset>?
    private var fetchedResultsControllerForSimilarSS: NSFetchedResultsController<DBAsset>?
    private var fetchedResultsControllerForOtherSS: NSFetchedResultsController<DBAsset>?
    
    
    override init() {
        super.init()
        dataSource = sectionsType.map({ tuple in
            let cells = tuple.cells.map { $0.cell }
            return (tuple.title, cells)
        })
        
        setupFetchtResultController(&fetchedResultsControllerForDuplicatePhotos, type: .duplicatePhoto)
        setupFetchtResultController(&fetchedResultsControllerForSimilarPhotos, type: .similarPhoto)
        setupFetchtResultController(&fetchedResultsControllerForOtherPhotos, type: .otherPhoto)
        setupFetchtResultController(&fetchedResultsControllerForDuplicateSS, type: .duplicateScreenshot)
        setupFetchtResultController(&fetchedResultsControllerForSimilarSS, type: .similarScreenshot)
        setupFetchtResultController(&fetchedResultsControllerForOtherSS, type: .otherScreenshot)
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
        return NSCompoundPredicate(andPredicateWithSubpredicates: [mediaPredicate, groupPredicate])
        
    }
    
    func setupFetchtResultController(_ controller: inout NSFetchedResultsController<DBAsset>?, type: MediaCellType){
        if controller == nil{
            let request = DBAsset.fetchRequest()
            let subGroupSort = NSSortDescriptor(key: "subGroupId", ascending: true)
            let dateSort = NSSortDescriptor(key: "creationDate", ascending: true)
            request.sortDescriptors = [subGroupSort, dateSort]
            
            request.predicate = getPredicate(mediaType: type)
            
            controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataManager.shared.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            
            do{
                try controller?.performFetch()
                updateCell(assets: controller?.fetchedObjects ?? [], type: type)
                
            } catch{
                print(error)
            }
        }
    }
    
    
    
    private func updateCell(assets: [DBAsset], type: MediaCellType){
        var cellAssets = [PHAsset]()
        var subId: UUID?
        let size = assets.reduce(Int64(0) ) { $0 + $1.size }
        
    outerloop: for (index, asset) in assets.enumerated(){
            switch type{
            case .otherPhoto, .otherScreenshot:   // append 5 photos for other
                if cellAssets.count == 5{
                    break outerloop
                }
            default:
                if cellAssets.count == 2{     // append 5 photos for duplicate and similar
                    break outerloop
                }
                
            if cellAssets.count > 1 {
                    if let subId{
                        // select second asset with same subId
                        if let selectedAsset = assets.filter({ $0.subGroupId == subId }).first, let asset = selectedAsset.getPHAsset(){
                            cellAssets.append(asset)
                            break outerloop
                        }
                    }
                }
            }
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


extension MediaViewModel: NSFetchedResultsControllerDelegate{
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        switch controller{
        case fetchedResultsControllerForDuplicatePhotos:
            updateCell(assets: fetchedResultsControllerForDuplicatePhotos?.fetchedObjects ?? [], type: .duplicatePhoto)
            break
        case fetchedResultsControllerForSimilarPhotos:
            updateCell(assets: fetchedResultsControllerForSimilarPhotos?.fetchedObjects ?? [], type: .similarPhoto)
            break
        case fetchedResultsControllerForOtherPhotos:
            updateCell(assets: fetchedResultsControllerForOtherPhotos?.fetchedObjects ?? [], type: .otherPhoto)
            break
        default:
            break
        }
    }
}
