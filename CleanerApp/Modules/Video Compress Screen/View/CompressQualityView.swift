//
//  CompressQualityView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI
import AVKit
import Photos

struct CompressQualityView: View {
    @StateObject private var viewModel: CompressQualityViewModel
    @Environment(\.dismiss) private var dismiss

    let onDataChanged: () -> Void

    init(compressAsset: CompressVideoModel, onDataChanged: @escaping () -> Void) {
        let destinationPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("compressed.mp4")
        try? FileManager.default.removeItem(at: destinationPath)

        var asset = compressAsset
        asset.compressor.destinationURL = destinationPath

        _viewModel = StateObject(wrappedValue: CompressQualityViewModel(compressAsset: asset))
        self.onDataChanged = onDataChanged
    }

    var body: some View {
        ZStack {
            Color.lightBlueDarkGrey
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Video Player
                videoPlayerView
                    .frame(height: 250)
                    .cornerRadius(20)
                    .padding(.horizontal)

                // Content based on state
                switch viewModel.compressionState {
                case .beforeCompression:
                    beforeCompressionView
                case .duringCompression:
                    duringCompressionView
                case .afterCompression:
                    afterCompressionView
                }

                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("Compress Video")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.compressionState == .duringCompression)
        .toolbar {
            if viewModel.compressionState == .duringCompression {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Stop") {
                        viewModel.showStopAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .alert("Leave Without Saving?", isPresented: $viewModel.showStopAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                viewModel.cancelCompression()
                dismiss()
            }
        } message: {
            Text("If you leave the app during compression, the video won't be saved.")
        }
        .onAppear {
            logEvent(Event.CompressQualityScreen.loaded.rawValue, parameter: nil)
        }
    }

    // MARK: - Video Player

    private var videoPlayerView: some View {
        VideoPlayerWrapper(asset: viewModel.compressAsset.avAsset, isPlaying: viewModel.compressionState == .beforeCompression)
            .overlay {
                if viewModel.compressionState != .beforeCompression {
                    Color.black.opacity(0.5)
                        .cornerRadius(20)
                }
            }
    }

    // MARK: - Before Compression View

    private var beforeCompressionView: some View {
        VStack(spacing: 16) {
            // Size info card
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Size")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.compressAsset.originalSize.convertToFileString())
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .foregroundColor(.blue)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Compressed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.compressAsset.reduceSize.convertToFileString())
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }

                savingsLabel
            }
            .padding()
            .background(Color(uiColor: .primaryCell))
            .cornerRadius(20)
            .padding(.horizontal)

            // Quality Selection
            qualitySelector

            // Compress Button
            Button {
                viewModel.startCompression {
                    onDataChanged()
                }
            } label: {
                Text("Compress Video")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }

    private var savingsLabel: some View {
        HStack {
            Text("You will save about")
                .font(.subheadline)
                .foregroundColor(.blue)
            Text((viewModel.compressAsset.originalSize - viewModel.compressAsset.reduceSize).convertToFileString())
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    private var qualitySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Compression Quality")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Picker("Quality", selection: $viewModel.selectedQuality) {
                Text("Optimal").tag(CompressionQuality.optimal)
                Text("Medium").tag(CompressionQuality.medium)
                Text("Maximum").tag(CompressionQuality.maximum)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }

    // MARK: - During Compression View

    private var duringCompressionView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("Compressing Video...")
                    .font(.headline)

                ProgressView(value: viewModel.compressionProgress)
                    .progressViewStyle(.linear)
                    .tint(.blue)

                Text("\(Int(viewModel.compressionProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(uiColor: .primaryCell))
            .cornerRadius(20)
            .padding(.horizontal)

            Text("Don't close the app. Otherwise, the video won't be compressed.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - After Compression View

    private var afterCompressionView: some View {
        VStack(spacing: 16) {
            // Success card
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)

                Text("Compression Complete!")
                    .font(.headline)

                HStack(spacing: 20) {
                    VStack {
                        Text("Before")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.compressAsset.originalSize.convertToFileString())
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Image(systemName: "arrow.right")
                        .foregroundColor(.green)

                    VStack {
                        Text("After")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.compressedSize.convertToFileString())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }

                Text("Space saved: \((viewModel.compressAsset.originalSize - viewModel.compressedSize).convertToFileString())")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(uiColor: .primaryCell))
            .cornerRadius(20)
            .padding(.horizontal)

            Text("What do you want to do with the original video?")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Action buttons
            HStack(spacing: 16) {
                Button {
                    dismiss()
                } label: {
                    Text("Keep Original")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }

                Button {
                    viewModel.deleteOriginal {
                        dismiss()
                    }
                } label: {
                    Text("Delete Original")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
                .disabled(viewModel.isDeletingOriginal)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Video Player Wrapper

struct VideoPlayerWrapper: UIViewControllerRepresentable {
    let asset: AVAsset
    let isPlaying: Bool

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerVC = AVPlayerViewController()
        let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        playerVC.player = player
        playerVC.view.backgroundColor = UIColor.primaryCell
        return playerVC
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if isPlaying {
            uiViewController.player?.play()
        } else {
            uiViewController.player?.pause()
        }
    }
}

// MARK: - Compression Quality Enum

enum CompressionQuality {
    case optimal
    case medium
    case maximum
}

// MARK: - ViewModel

@MainActor
class CompressQualityViewModel: ObservableObject {
    @Published var compressAsset: CompressVideoModel
    @Published var compressionState: CompressionState = .beforeCompression
    @Published var compressionProgress: Double = 0
    @Published var compressedSize: Int64 = 0
    @Published var showStopAlert = false
    @Published var isDeletingOriginal = false

    @Published var selectedQuality: CompressionQuality = .optimal {
        didSet {
            updateQuality()
        }
    }

    enum CompressionState {
        case beforeCompression
        case duringCompression
        case afterCompression
    }

    init(compressAsset: CompressVideoModel) {
        self.compressAsset = compressAsset
    }

    private func updateQuality() {
        switch selectedQuality {
        case .optimal:
            compressAsset.compressor.quality = .very_high
        case .medium:
            compressAsset.compressor.quality = .high
        case .maximum:
            compressAsset.compressor.quality = .medium
        }
        // Trigger UI update for estimated size
        objectWillChange.send()
    }

    func startCompression(onDataChanged: @escaping () -> Void) {
        logEvent(Event.CompressQualityScreen.compressButtonPressed.rawValue, parameter: nil)

        compressAsset.compressor.compressVideo { [weak self] progress in
            DispatchQueue.main.async {
                self?.compressionProgress = progress.fractionCompleted
            }
        } completion: { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .onStart:
                DispatchQueue.main.async {
                    self.compressionState = .duringCompression
                }
                logEvent(Event.CompressQualityScreen.compressStatus.rawValue, parameter: ["status": "started"])

            case .onSuccess(let url):
                onDataChanged()
                logEvent(Event.CompressQualityScreen.compressStatus.rawValue, parameter: ["status": "Compressed"])

                self.saveVideoToPhotosLibrary(videoURL: url) { size, error in
                    DispatchQueue.main.async {
                        if let error {
                            logEvent(Event.CompressQualityScreen.savePhotoToGalleryStatus.rawValue, parameter: ["status": error.localizedDescription])
                        } else {
                            logEvent(Event.CompressQualityScreen.savePhotoToGalleryStatus.rawValue, parameter: ["status": "saved"])
                            self.compressedSize = size
                            self.compressionState = .afterCompression
                        }
                    }
                }

            case .onFailure(let error):
                logEvent(Event.CompressQualityScreen.compressStatus.rawValue, parameter: ["status": error.localizedDescription])
                DispatchQueue.main.async {
                    self.compressionState = .beforeCompression
                }

            case .onCancelled:
                logEvent(Event.CompressQualityScreen.compressStatus.rawValue, parameter: ["status": "Cancelled"])
            }
        }
    }

    func cancelCompression() {
        compressAsset.compressor.compressionOperation.cancel = true
    }

    func deleteOriginal(completion: @escaping () -> Void) {
        logEvent(Event.CompressQualityScreen.deleteOriginalButtonPressed.rawValue, parameter: nil)
        isDeletingOriginal = true

        compressAsset.phAsset.delete { [weak self] isComplete, error in
            DispatchQueue.main.async {
                self?.isDeletingOriginal = false
                if isComplete {
                    completion()
                }
            }
        }
    }

    private func saveVideoToPhotosLibrary(videoURL: URL, completion: @escaping (Int64, Error?) -> Void) {
        var identifier: String = ""
        PHPhotoLibrary.shared().performChanges {
            let changeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            identifier = changeRequest?.placeholderForCreatedAsset?.localIdentifier ?? ""
        } completionHandler: { success, error in
            let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: .none)
            let size = asset.firstObject?.getSize() ?? 0
            completion(size, error)
        }
    }
}

#Preview {
    NavigationStack {
        Text("Preview requires video asset")
    }
}
