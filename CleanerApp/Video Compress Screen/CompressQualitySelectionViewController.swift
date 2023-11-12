//
//  CompressQualitySelectionViewController.swift
//  CleanerApp
//
//  Created by manu on 12/11/23.
//

import UIKit

class CompressQualitySelectionViewController: UIViewController {

    //MARK: - Life cycles
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: - static functions
    static func initWith() -> CompressQualitySelectionViewController{
        UIStoryboard(name: Storyboard.VideoCompress.rawValue, bundle: nil).instantiateViewController(withIdentifier: "CompressQualitySelectionViewController") as! CompressQualitySelectionViewController
    }
}
