//
//  ReferAFriendView.swift
//  CleanerApp
//
//  Created by Sneha Tyagi on 13/10/24.
//

import SwiftUI
import UIKit

struct ReferAFriendView: UIViewControllerRepresentable {
    var shareText: String
    var appLink: URL
    
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let itemsToShare: [Any] = [shareText, appLink]
        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
                   self.presentationMode.wrappedValue.dismiss() // Dismiss the view after sharing
               }
        return activityViewController
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update required
    }
}
