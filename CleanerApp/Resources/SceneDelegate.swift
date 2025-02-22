//
//  SceneDelegate.swift
//  CleanerApp
//
//  Created by manu on 05/11/23.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appearanceMode: AppearanceMode = .system

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
//        guard let _ = (scene as? UIWindowScene) else { return }
        
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
               self.window = window
               
        let initialViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LaunchViewController")
        window.rootViewController = initialViewController
        window.makeKeyAndVisible()
        
        updateAppearance()
                // Create a new UIWindow using the windowScene constructor
//                let window = UIWindow(windowScene: windowScene)
//
//                // Create an instance of your custom tab bar controller
//                let customTabBarController = MyTabbarViewController()
//        
//        window.rootViewController = customTabBarController
//        window.makeKeyAndVisible()
//        self.window = window
    }
    
    private func updateAppearance() {
        let appearanceModeRawValue = UserDefaults.standard.string(forKey: UserDefaultKeys.appearance.rawValue) ?? ""
        let appearanceMode = AppearanceMode(rawValue: appearanceModeRawValue) ?? .dark
            switch appearanceMode {
            case .system:
                window?.overrideUserInterfaceStyle = .unspecified
            case .light:
                window?.overrideUserInterfaceStyle = .light
            case .dark:
                window?.overrideUserInterfaceStyle = .dark
            }
        }

        func changeAppearance(to mode: AppearanceMode) {
            UserDefaults.standard.set(mode.rawValue, forKey: UserDefaultKeys.appearance.rawValue)
            updateAppearance()
        }
    
    

    func sceneDidDisconnect(_ scene: UIScene) {
        logEvent(Event.appTerminated.rawValue, parameter: nil)
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        CoreDataPHAssetManager.shared.startProcessingPhotos()
        logEvent(Event.appEnterForeground.rawValue, parameter: nil)
        
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        logEvent(Event.appEnterBackground.rawValue, parameter: nil)
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
//        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

