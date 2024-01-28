//
//  DuplicatePhotosViewController.swift
//  CleanerApp
//
//  Created by Manu on 05/01/24.
//

import UIKit

class DuplicatePhotosViewController: BaseViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
//    override class func customInit(predicate: NSPredicate, groupType: PHAssetGroupType) -> BaseViewController {
//        let baseVC = customInit(predicate: predicate, groupType: groupType)
//       object_setClass(baseVC, DuplicatePhotosViewController.self)
//        return baseVC as! DuplicatePhotosViewController
//    }

}


class SimilarPhotosViewController: BaseViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    
    class func customInit() -> SimilarPhotosViewController{
        let mediaPredicate = NSPredicate(format: "mediaTypeValue == %@", PHAssetCustomMediaType.photo.rawValue)
        let groupPredicate = NSPredicate(format: "groupTypeValue == %@", PHAssetGroupType.similar.rawValue)
        
        let compountPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [mediaPredicate, groupPredicate])
        
        let baseVC = customInit(predicate: compountPredicate, groupType: .similar)
       object_setClass(baseVC, SimilarPhotosViewController.self)
        return baseVC as! SimilarPhotosViewController
    }

}
