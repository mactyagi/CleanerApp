//
//  TabViewController.swift
//  CleanerApp
//
//  Created by Manukant Tyagi on 17/08/24.
//

import Foundation
import UIKit
import SwiftUI
import Contacts

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
        // Home VC - Using new SwiftUI HomeScreen
        let homeVC = HomeScreenHostingController()
        let homeNavVC = UINavigationController(rootViewController: homeVC)
        homeNavVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))

        // compress VC - Using SwiftUI Stats Focus design
        let compressNavVC = UINavigationController(rootViewController: VideoCompressorHostingController())
        compressNavVC.tabBarItem = UITabBarItem(title: "Compressor", image: UIImage(systemName: "digitalcrown.horizontal.press"), selectedImage: UIImage(systemName: "digitalcrown.horizontal.press.fill"))

        // Setting VC
        let settingVC = SettingViewSwiftUIVC()
        settingVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear.circle"), selectedImage: UIImage(systemName: "gear.circle.fill"))

        viewControllers = [homeNavVC, compressNavVC, settingVC]
    }
}

// MARK: - Home Screen Hosting Controller
class HomeScreenHostingController: UIViewController {
    private var hostingController: UIHostingController<HomeScreen>?

    override func viewDidLoad() {
        super.viewDidLoad()

        let homeScreen = HomeScreen(
            onMediaTapped: { [weak self] in
                let mediaVC = MediaScreenHostingController()
                self?.navigationController?.pushViewController(mediaVC, animated: true)
            },
            onContactsTapped: { [weak self] in
                let viewModel = OrganizeContactViewModel(contactStore: CNContactStore())
                let contactsVC = OrganizeContactsViewController.customInit(viewModel: viewModel)
                self?.navigationController?.pushViewController(contactsVC, animated: true)
            },
            onCalendarTapped: { [weak self] in
                let calendarView = CalendarDesignSelector()
                let calendarVC = UIHostingController(rootView: calendarView)
                calendarVC.title = "Calendar"
                self?.navigationController?.pushViewController(calendarVC, animated: true)
            },
            onCompressTapped: { [weak self] in
                let compressVC = VideoCompressorHostingController()
                self?.navigationController?.pushViewController(compressVC, animated: true)
            }
        )

        let hosting = UIHostingController(rootView: homeScreen)
        addChild(hosting)
        hosting.view.frame = view.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
        hostingController = hosting
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
