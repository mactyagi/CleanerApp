//
//  PrivacyPolicyViewControllerWrapper.swift
//  CleanerApp
//
//  Created by Sneha Tyagi on 13/10/24.
//

import UIKit
import SwiftUI


struct PrivacyPolicyViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PrivacyPolicyViewController {
        PrivacyPolicyViewController()
            
    }
    
    func updateUIViewController(_ uiViewController: PrivacyPolicyViewController, context: Context) {
    }
}
