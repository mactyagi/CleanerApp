//
//  ReportAnErrorViewControllerWrapper.swift
//  CleanerApp
//
//  Created by Sneha Tyagi on 14/10/24.
//


import SwiftUI
import UIKit

// Step 1: Create a Wrapper for ReportErrorViewController
struct ReportErrorViewControllerWrapper: UIViewControllerRepresentable {
    
    // The makeUIViewController method creates and returns an instance of the ReportErrorViewController.
    func makeUIViewController(context: Context) -> ReportErrorViewController {
        let storyboard = UIStoryboard(name: "Setting", bundle: nil)
        let reportErrorVC = storyboard.instantiateViewController(identifier: "ReportErrorViewController") as! ReportErrorViewController
        return reportErrorVC
    }

    // The updateUIViewController method can be used to update the UIKit view controller when SwiftUI state changes (if needed).
    func updateUIViewController(_ uiViewController: ReportErrorViewController, context: Context) {
        // You can update the UI here if needed, based on SwiftUI state
    }
}
