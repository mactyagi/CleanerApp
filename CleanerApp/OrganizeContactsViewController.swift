//
//  OrganizeContactsViewController.swift
//  CleanerApp
//
//  Created by Manu on 20/02/24.
//

import UIKit

class OrganizeContactsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    
    //MARK: - Static Function
    static let identifier = "OrganizeContactsViewController"
    static func customInit() -> OrganizeContactsViewController{
        let vc = UIStoryboard.main.instantiateViewController(identifier: Self.identifier) as! Self
        return vc
    }

}
