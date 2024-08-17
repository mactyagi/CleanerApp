//
//  ComingSoonViewController.swift
//  CleanerApp
//
//  Created by Manu on 01/02/24.
//

import UIKit

class ComingSoonViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.makeCornerRadiusFourthOfHeightOrWidth()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationAndTabBar(isScreenVisible: false)
    }
    
    @IBAction func backButtonPressed(){
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true)
    }
    
    static func customInit() -> ComingSoonViewController{
        let vc = UIStoryboard.home.instantiateViewController(identifier: ComingSoonViewController.className) as! ComingSoonViewController
        return vc
    }
}
