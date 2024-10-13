//
//  PrivacyPolicyViewController.swift
//  CleanerApp
//
//  Created by Sneha Tyagi on 15/05/24.
//

import UIKit
import WebKit
import SwiftUI

    class PrivacyPolicyViewController: UIViewController{
        
        
        //MARK: - IBOutlet
        var webView: WKWebView!
        
            //MARK: - lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpView()
            
        }
        
        override func viewWillAppear(_ animated: Bool) {
            tabBarController?.tabBar.isHidden = true
            super.viewWillAppear(animated)
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        
        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            navigationController?.navigationBar.isHidden = false
            tabBarController?.tabBar.isHidden = false
        }
        
        override func loadView() {
            webView = WKWebView()
            webView.navigationDelegate = self
            view = webView
            
        }
        
        
        //MARK: - setup fuctions
        func setUpView(){
            title = "Privacy Policy"
            let url = URL(string: "https://www.termsfeed.com/live/7cf1c096-c229-4f85-a616-6c76e43fb351")!
            webView.load(URLRequest(url: url))
            webView.allowsBackForwardNavigationGestures = true
        }
  }


    //MARK: - Web view delegate
    extension PrivacyPolicyViewController : WKNavigationDelegate {
        
    }

//}
