//
//  CompressorFlowViews.swift
//  CleanerApp
//
//  Pure SwiftUI views for Compressor navigation flow
//

import SwiftUI

// MARK: - Compressor Detail View (For navigation from Home tab)
struct CompressorDetailView: View {
    @StateObject private var viewModel = VideoCompressViewModel()
    @State private var selectedVideo: CompressVideoModel?
    @State private var showQualitySelection = false
    
    var body: some View {
        VideoCompressorView(
            viewModel: viewModel,
            onVideoSelected: { video in
                selectedVideo = video
                showQualitySelection = true
            }
        )
        .navigationDestination(isPresented: $showQualitySelection) {
            if let video = selectedVideo {
                CompressQualityDetailView(video: video, onComplete: {
                    showQualitySelection = false
                    viewModel.fetchData()
                })
            }
        }
        .onAppear {
            viewModel.fetchData()
        }
    }
}

// MARK: - Compress Quality Detail View
struct CompressQualityDetailView: View {
    let video: CompressVideoModel
    let onComplete: () -> Void
    
    var body: some View {
        CompressQualitySelectionViewWrapper(video: video, onComplete: onComplete)
            .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - Compress Quality Selection View Wrapper
struct CompressQualitySelectionViewWrapper: View {
    let video: CompressVideoModel
    let onComplete: () -> Void
    
    @StateObject private var viewModelWrapper: ViewModelWrapper
    
    init(video: CompressVideoModel, onComplete: @escaping () -> Void) {
        self.video = video
        self.onComplete = onComplete
        
        // Setup destination path
        let destinationPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("compressed.mp4")
        try? FileManager.default.removeItem(at: destinationPath)
        
        var compressAssetCopy = video
        compressAssetCopy.compressor.destinationURL = destinationPath
        compressAssetCopy.compressor.quality = .high
        
        let viewModel = CompressQualitySelectionViewModel(compressAsset: compressAssetCopy)
        _viewModelWrapper = StateObject(wrappedValue: ViewModelWrapper(viewModel: viewModel))
    }
    
    var body: some View {
        CompressQualitySelectionView(
            viewModel: viewModelWrapper.viewModel,
            onDismiss: onComplete,
            onDataChanged: onComplete
        )
    }
}
