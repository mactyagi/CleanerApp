//
//  LoaderViewController.swift
//  CleanerApp
//
//  Created by Manu on 19/02/24.
//

import UIKit

class LoaderViewController: UIViewController {

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    static let identifier = "LoaderViewController"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicatorView.startAnimating()
    }


}
