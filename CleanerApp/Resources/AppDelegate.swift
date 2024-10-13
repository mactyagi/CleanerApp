//
//  AppDelegate.swift
//  CleanerApp
//
//  Created by manu on 05/11/23.
//

import UIKit
import CoreData
import Photos
import FirebaseCore
import FirebaseFirestore
import FirebaseAnalytics
import FirebaseCrashlytics

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    
    func configureFirebase() {
        DispatchQueue.global(qos: .background).async {
            #if APPSTORE
            // Enable Firebase Analytics for App Store builds
            Analytics.setAnalyticsCollectionEnabled(true)
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
            print("Firebase Analytics and Crashlytics enabled for App Store build")
            #else
            // Ensure Firebase Analytics is disabled for non-App Store builds
            Analytics.setAnalyticsCollectionEnabled(false)
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
            print("Firebase Analytics and Crashlytics disabled for non-App Store build")
            #endif
        }
    
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        configureFirebase()
        logEvent(Event.appLaunched.rawValue, parameter: nil)
        // Override point for customization after application launch.
        return true
    }
    
    
    

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CleanerApp")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                logError(error: error, VCName: "AppDelegate", functionName: #function, line: #line)
            }
        })
        return container
    }()
}

