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
    
    
    
    override class func customInit() -> DuplicatePhotosViewController{
        let baseVC = super.customInit()
        
        let mediaPredicate = NSPredicate(format: "mediaTypeValue == %@", PHAssetCustomMediaType.photo.rawValue)
        let groupPredicate = NSPredicate(format: "groupTypeValue == %@", PHAssetGroupType.duplicate.rawValue)
        
        let compountPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [mediaPredicate, groupPredicate])
        baseVC.predicate = compountPredicate
       object_setClass(baseVC, DuplicatePhotosViewController.self)
        return baseVC as! DuplicatePhotosViewController
    }

}
