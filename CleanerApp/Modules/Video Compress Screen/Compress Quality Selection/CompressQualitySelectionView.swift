//
//  CompressQualitySelectionView.swift
//  CleanerApp
//
//  SwiftUI Classic Card Design for Video Compression Quality Selection
//

import SwiftUI
import UIKit
import AVKit
import Combine

// MARK: - Compression State
enum CompressState {
    case beforeCompress
    case compressing
    case completed
}

// MARK: - Quality Option
enum QualityOption: Int, CaseIterable {
    case optimal = 0
    case medium = 1
    case maximum = 2

    var title: String {
        switch self {
        case .optimal: return "Optimal"
        case .medium: return "Medium"
        case .maximum: return "Maximum"
        }
    }
}

// MARK: - Main View
struct CompressQualitySelectionView: View {
    @StateObject var viewModelWrapper: ViewModelWrapper
    @State private var state: CompressState = .beforeCompress
    @State private var selectedQuality: QualityOption = .medium
    @State private var progress: Float = 0
    @State private var compressedSize: Int64 = 0
    @State private var spaceSaved: Int64 = 0

    var onDismiss: (() -> Void)?
    var onDataChanged: (() -> Void)?

    init(viewModel: CompressQualitySelectionViewModel, onDismiss: (() -> Void)? = nil, onDataChanged: (() -> Void)? = nil) {
        _viewModelWrapper = StateObject(wrappedValue: ViewModelWrapper(viewModel: viewModel))
        self.onDismiss = onDismiss
        self.onDataChanged = onDataChanged
    }

    private var viewModel: CompressQualitySelectionViewModel {
        viewModelWrapper.viewModel
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                videoPlayer
                content
                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden(state == .compressing)
    }

    // MARK: - Video Player
    private var videoPlayer: some View {
        VideoPlayerView(asset: viewModel.compressAsset.avAsset)
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        switch state {
        case .beforeCompress:
            beforeCompressView
        case .compressing:
            compressingView
        case .completed:
            completedView
        }
    }

    // MARK: - Before Compress View
    private var beforeCompressView: some View {
        VStack(spacing: 16) {
            sizeInfoCard
            qualitySelector
            savingsText
            compressButton
        }
    }

    private var sizeInfoCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Original")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.compressAsset.originalSize.convertToFileString())
                    .font(.title3.bold())
            }

            Spacer()

            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Compressed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.compressAsset.reduceSize.convertToFileString())
                    .font(.title3.bold())
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    private var qualitySelector: some View {
        VStack(spacing: 12) {
            Text("Select Quality")
                .font(.headline)

            Picker("Quality", selection: $selectedQuality) {
                ForEach(QualityOption.allCases, id: \.self) { quality in
                    Text(quality.title).tag(quality)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedQuality) { newValue in
                updateQuality(newValue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    private var savingsText: some View {
        let savings = viewModel.compressAsset.originalSize - viewModel.compressAsset.reduceSize
        return HStack(spacing: 4) {
            Text("You will save about")
                .foregroundColor(.blue)
            Text(savings.convertToFileString())
                .fontWeight(.bold)
        }
    }

    private var compressButton: some View {
        Button {
            startCompression()
        } label: {
            Text("Compress Video")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.blue)
                )
        }
    }

    // MARK: - Compressing View
    private var compressingView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("Compressing Video...")
                    .font(.headline)

                ProgressView(value: Double(progress))
                    .progressViewStyle(.linear)
                    .tint(.blue)

                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )

            Text("Don't close the app. Otherwise, the video won't be compressed.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                stopCompression()
            } label: {
                Text("Stop")
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Completed View
    private var completedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)

            Text("Compression Complete!")
                .font(.headline)

            Text("Space saved: \(spaceSaved.convertToFileString())")
                .foregroundColor(.green)

            Text("What do you want to do with the original video?")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            actionButtons
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                onDismiss?()
            } label: {
                Text("Keep Original")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
            }

            Button {
                deleteOriginal()
            } label: {
                Text("Delete Original")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red)
                    )
            }
        }
    }

    // MARK: - Actions
    private func updateQuality(_ quality: QualityOption) {
        switch quality {
        case .optimal:
            viewModel.optimalQualitySelected()
        case .medium:
            viewModel.MediumQualitySelected()
        case .maximum:
            viewModel.MaxQualitySelected()
        }
        viewModelWrapper.objectWillChange.send()
    }

    private func startCompression() {
        withAnimation {
            state = .compressing
        }

        viewModel.compressAsset.compressor.compressVideo { progressValue in
            DispatchQueue.main.async {
                self.progress = Float(progressValue.fractionCompleted)
            }
        } completion: { result in
            switch result {
            case .onStart:
                print("Compression started")
            case .onSuccess(let url):
                onDataChanged?()
                viewModel.saveVideoToPhotosLibrary(videoURL: url) { size, error in
                    DispatchQueue.main.async {
                        if error == nil {
                            self.compressedSize = size
                            self.spaceSaved = viewModel.compressAsset.originalSize - size
                            withAnimation {
                                self.state = .completed
                            }
                        }
                    }
                }
            case .onFailure(let error):
                print("Compression failed: \(error)")
            case .onCancelled:
                print("Compression cancelled")
            }
        }
    }

    private func stopCompression() {
        viewModel.compressAsset.compressor.compressionOperation.cancel = true
        onDismiss?()
    }

    private func deleteOriginal() {
        viewModel.compressAsset.phAsset.delete { isComplete, error in
            if isComplete {
                DispatchQueue.main.async {
                    onDismiss?()
                }
            }
        }
    }
}

// MARK: - ViewModel Wrapper for SwiftUI
class ViewModelWrapper: ObservableObject {
    let viewModel: CompressQualitySelectionViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: CompressQualitySelectionViewModel) {
        self.viewModel = viewModel

        viewModel.$compressAsset
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Video Player View
struct VideoPlayerView: UIViewControllerRepresentable {
    let asset: AVAsset

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        playerViewController.player = player
        playerViewController.view.backgroundColor = UIColor.primaryCell
        playerViewController.view.layer.cornerRadius = 20
        playerViewController.view.clipsToBounds = true
        player.play()
        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

// MARK: - Hosting Controller
class CompressQualitySelectionHostingController: UIHostingController<CompressQualitySelectionView> {
    var dataChangedHandler: (() -> Void)?

    init(compressAsset: CompressVideoModel) {
        let destinationPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("compressed.mp4")
        try? FileManager.default.removeItem(at: destinationPath)

        var compressAssetCopy = compressAsset
        compressAssetCopy.compressor.destinationURL = destinationPath
        // Set default quality to Medium (.high)
        compressAssetCopy.compressor.quality = .high

        let viewModel = CompressQualitySelectionViewModel(compressAsset: compressAssetCopy)

        super.init(rootView: CompressQualitySelectionView(viewModel: viewModel))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Update rootView with callbacks
        rootView = CompressQualitySelectionView(
            viewModel: (rootView as CompressQualitySelectionView).viewModelWrapper.viewModel,
            onDismiss: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onDataChanged: { [weak self] in
                self?.dataChangedHandler?()
            }
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
        navigationController?.tabBarController?.tabBar.isHidden = true
    }
}
