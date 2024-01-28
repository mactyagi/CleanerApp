//
//  MyTabbarViewController.swift
//  CleanerApp
//
//  Created by Manu on 18/01/24.
//

import Foundation
import UIKit

class MyTabbarViewController: UITabBarController {
      
 
    override func viewDidLoad() {
        super.viewDidLoad()
//        setupTabBarAppearance()
//        setupViewController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        setupViewController()
    }
    
    private func setupTabBarAppearance() {
           tabBar.tintColor = UIColor.blue
           tabBar.barTintColor = UIColor.white
           // Add more customization as needed
       }
    
    
    func setupViewController(){
        let tempVC = TempViewController.customInit()
        
        let gallaryNavVC = UINavigationController(rootViewController: tempVC)
        
        gallaryNavVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"),selectedImage: UIImage(systemName: "house.fill"))
        
        let videoCompressorVC = VideoCompressorViewController.initWith()
        videoCompressorVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "rectangle.compress.vertical"),selectedImage: UIImage(systemName: "rectangle.compress.vertical"))
        
//        viewControllers = [ videoCompressorVC, gallaryNavVC]
    }
    
}
