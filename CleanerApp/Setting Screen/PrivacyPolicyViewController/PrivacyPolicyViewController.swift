//
//  PrivacyPolicyViewController.swift
//  CleanerApp
//
//  Created by Sneha Tyagi on 15/05/24.
//

import UIKit

class PrivacyPolicyViewController: UIViewController {
    


    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        // Do any additional setup after loading the view.
    }
    
    func setUpView(){
        title = "Privacy Policy"
//        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }
}
