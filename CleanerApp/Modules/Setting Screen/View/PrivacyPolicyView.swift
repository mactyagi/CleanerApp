//
//  PrivacyPolicyView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI
import WebKit

struct PrivacyPolicyView: View {
    private let privacyPolicyURL = "https://www.termsfeed.com/live/7cf1c096-c229-4f85-a616-6c76e43fb351"

    var body: some View {
        WebView(url: URL(string: privacyPolicyURL)!)
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
