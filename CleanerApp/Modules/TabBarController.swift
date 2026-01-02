//
//  TabViewController.swift
//  CleanerApp
//
//  Created by Manukant Tyagi on 17/08/24.
//

import Foundation
import UIKit
import SwiftUI

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
        // Home VC - Now SwiftUI
        let homeVC = HomeSwiftUIVC()
        homeVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))

        // Compress VC - Now SwiftUI
        let compressVC = VideoCompressorSwiftUIVC()
        compressVC.tabBarItem = UITabBarItem(title: "Compressor", image: UIImage(systemName: "digitalcrown.horizontal.press"), selectedImage: UIImage(systemName: "digitalcrown.horizontal.press.fill"))

        // Setting VC
        let settingVC = SettingViewSwiftUIVC()
        settingVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear.circle"), selectedImage: UIImage(systemName: "gear.circle.fill"))

        viewControllers = [homeVC, compressVC, settingVC]
    }
}

// MARK: - SwiftUI Hosting Controllers

class HomeSwiftUIVC: UIHostingController<HomeView> {
    init() {
        super.init(rootView: HomeView())
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class VideoCompressorSwiftUIVC: UIHostingController<VideoCompressorView> {
    init() {
        super.init(rootView: VideoCompressorView())
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SettingViewSwiftUIVC: UIHostingController<SettingView> {
    init() {
        super.init(rootView: SettingView())
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
