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
    
    
    @IBAction func backButtonPressed(){
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true)
    }
    
    static func customInit() -> ComingSoonViewController{
        let vc = UIStoryboard.main.instantiateViewController(identifier: "ComingSoonViewController") as! ComingSoonViewController
        return vc
    }
}
