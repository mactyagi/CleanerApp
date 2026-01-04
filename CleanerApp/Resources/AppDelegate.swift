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

// Note: @main removed - SwiftUI App struct (CleanerApp.swift) is now the entry point
class AppDelegate: UIResponder, UIApplicationDelegate {

    func configureFirebase() {
        #if APPSTORE
        Analytics.setAnalyticsCollectionEnabled(true)
        print("Firebase Analytics enabled for App Store build")
        #else
        Analytics.setAnalyticsCollectionEnabled(false)
        print("Firebase Analytics disabled for non-App Store build")
        #endif
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        configureFirebase()
        logEvent(Event.appLaunched.rawValue, parameter: nil)
        return true
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

