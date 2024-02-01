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

        
    }
}


class SimilarPhotosViewController: BaseViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
}


class OtherPhotosViewController: BaseViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func selectAll() {
        guard let sections = fetchResultViewController.sections else { return }
        for (index,section) in sections.enumerated() {
            let rowsCount = section.numberOfObjects
            for index2 in 0 ..< rowsCount{
                let indexpath = IndexPath(row: index2, section: index)
                viewModel.selectedIndexPath.insert(indexpath)
            }
        }
        reloadData()
    }
}
