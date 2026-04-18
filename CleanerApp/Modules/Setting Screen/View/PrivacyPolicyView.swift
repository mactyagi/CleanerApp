//
//  PrivacyPolicyView.swift
//  CleanerApp
//
//  SwiftUI Privacy Policy WebView
//

import SwiftUI
import WebKit

struct PrivacyPolicyView: View {
    var body: some View {
        WebView(url: URL(string: "https://www.termsfeed.com/live/7cf1c096-c229-4f85-a616-6c76e43fb351")!)
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
