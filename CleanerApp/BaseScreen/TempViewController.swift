//
//  TempViewController.swift
//  CleanerApp
//
//  Created by Manu on 20/01/24.
//

import UIKit

class TempViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
//        let vc = HomeViewController.customInit()
//        vc.modalPresentationStyle = .fullScreen
//        present(vc, animated: false)
    }
    
    static func customInit() -> TempViewController{
        let vc = UIStoryboard.main.instantiateViewController(identifier: "TempViewController") as! TempViewController
        return vc
    }
  
}
