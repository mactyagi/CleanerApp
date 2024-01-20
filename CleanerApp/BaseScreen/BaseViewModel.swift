//
//  BaseViewModel.swift
//  CleanerApp
//
//  Created by Manu on 05/01/24.
//

import Foundation
import Combine
class BaseViewModel{
    
    var assetRows: [[CustomDBAsset]] = []
   @Published var selectedIndexPath: Set<IndexPath> = []
    
    var predicate: NSPredicate
    init(predicate: NSPredicate) {
        self.predicate = predicate
//        fetchDBAssetFromCoreData()
    }
    
    func fetchDBAssetFromCoreData(){
        let context = CoreDataManager.shared.persistentContainer.viewContext
        let dbAssets = CoreDataManager.shared.fetchDBAssets(context: context, predicate: self.predicate)
        let dict = Dictionary(grouping: dbAssets) { $0.subGroupId }
        for (key,value) in dict{
            var assets: [CustomDBAsset] = []
            for (index,asset) in value.enumerated(){
                assets.append(CustomDBAsset(dbAsset: asset, isSelected: index != 0))
            }
            assetRows.append(assets)
        }
    }
}


struct CustomDBAsset{
    var dbAsset: DBAsset
    var isSelected: Bool
}
