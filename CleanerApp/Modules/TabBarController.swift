//
//  TabViewController.swift
//  CleanerApp
//
//  Created by Manukant Tyagi on 17/08/24.
//

import Foundation
import UIKit

class TabBarController : UITabBarController{

    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupControllers()
    }

    //MARK: - static functions
    static func customInit() -> Self {
        UIStoryboard.main.instantiateViewController(withIdentifier: Self.className) as! Self
    }

    //MARK: - private functions
    private func setupControllers() {
        // Home VC
        let homeNavVC = UINavigationController(rootViewController: HomeViewController.customInit())
        homeNavVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))

        // compress VC
        let compressNavVC = UINavigationController(rootViewController: VideoCompressorViewController.initWith())
        compressNavVC.tabBarItem = UITabBarItem(title: "Compressor", image: UIImage(systemName: "digitalcrown.horizontal.press"), selectedImage: UIImage(systemName: "digitalcrown.horizontal.press.fill"))

        // Setting VC
        let settingNavVC = UINavigationController(rootViewController: SettingViewController.customInit())
        settingNavVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear.circle"), selectedImage: UIImage(systemName: "gear.circle.fill"))

        viewControllers = [homeNavVC, compressNavVC, settingNavVC]

    }
}
