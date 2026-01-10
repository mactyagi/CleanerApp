//
//  VideoCompressorView.swift
//  CleanerApp
//
//  SwiftUI Stats Focus Design for Video Compressor Screen
//

import SwiftUI
import UIKit
import Photos
import Combine

// MARK: - Sort Option
enum VideoSortOption: String, CaseIterable {
    case sizeDesc = "Largest First"
    case sizeAsc = "Smallest First"
    case dateDesc = "Newest First"
    case dateAsc = "Oldest First"

    var icon: String {
        switch self {
        case .sizeDesc: return "arrow.down.circle"
        case .sizeAsc: return "arrow.up.circle"
        case .dateDesc: return "calendar.badge.clock"
        case .dateAsc: return "calendar"
        }
    }
}

// MARK: - Video Compressor View (Stats Focus Design)
struct VideoCompressorView: View {
    @StateObject private var viewModelWrapper: CompressorViewModelWrapper
    @State private var selectedSort: VideoSortOption = .sizeDesc
    @State private var showSortMenu = false
    var onVideoSelected: ((CompressVideoModel) -> Void)?

    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    init(viewModel: VideoCompressViewModel, onVideoSelected: ((CompressVideoModel) -> Void)? = nil) {
        _viewModelWrapper = StateObject(wrappedValue: CompressorViewModelWrapper(viewModel: viewModel))
        self.onVideoSelected = onVideoSelected
    }

    private var viewModel: VideoCompressViewModel {
        viewModelWrapper.viewModel
    }

    private var sortedVideos: [CompressVideoModel] {
        switch selectedSort {
        case .sizeDesc:
            return viewModel.compressVideoModel.sorted { $0.originalSize > $1.originalSize }
        case .sizeAsc:
            return viewModel.compressVideoModel.sorted { $0.originalSize < $1.originalSize }
        case .dateDesc:
            return viewModel.compressVideoModel.sorted { $0.phAsset.creationDate ?? Date() > $1.phAsset.creationDate ?? Date() }
        case .dateAsc:
            return viewModel.compressVideoModel.sorted { $0.phAsset.creationDate ?? Date() < $1.phAsset.creationDate ?? Date() }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("Loading videos...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    statsHeader
                    videoGrid
                }
            }
        }
    }

    // MARK: - Stats Header
    private var statsHeader: some View {
        VStack(spacing: 16) {
            Text("Video Compressor")
                .font(.headline)
                .foregroundColor(.secondary)

            // Main Stat - Potential Savings
            VStack(spacing: 4) {
                Text("Potential Savings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text((viewModel.totalSize - viewModel.totalCompressSize).convertToFileString())
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.blue)
            }

            // Secondary Stats
            HStack(spacing: 24) {
                VStack {
                    Text("\(viewModel.compressVideoModel.count)")
                        .font(.title2.bold())
                    Text("Videos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack {
                    Text(viewModel.totalSize.convertToFileString())
                        .font(.title2.bold())
                    Text("Total Size")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Sort Button - Right aligned
            HStack {
                Spacer()
                Menu {
                    ForEach(VideoSortOption.allCases, id: \.self) { option in
                        Button {
                            selectedSort = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if selectedSort == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(selectedSort.rawValue)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                }
                .foregroundColor(.primary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.15), Color(UIColor.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Video Grid
    private var videoGrid: some View {
        ScrollView {
            if viewModel.compressVideoModel.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(sortedVideos, id: \.phAsset.localIdentifier) { video in
                        VideoCompressorCell(video: video)
                            .onTapGesture {
                                onVideoSelected?(video)
                            }
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Videos Found")
                .font(.headline)
            Text("Videos from your library will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Video Cell
struct VideoCompressorCell: View {
    let video: CompressVideoModel
    @State private var thumbnail: UIImage?

    var body: some View {
        VStack(spacing: 8) {
            // Thumbnail
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    )
            }

            // Size Info
            HStack {
                Text(video.originalSize.convertToFileString())
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(video.compressor.estimatedOutputSize().convertToFileString())
                    .font(.caption.bold())
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
        )
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        video.phAsset.getImage { image in
            DispatchQueue.main.async {
                self.thumbnail = image
            }
        }
    }
}

// MARK: - ViewModel Wrapper
class CompressorViewModelWrapper: ObservableObject {
    let viewModel: VideoCompressViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: VideoCompressViewModel) {
        self.viewModel = viewModel

        viewModel.$compressVideoModel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Hosting Controller
class VideoCompressorHostingController: UIHostingController<VideoCompressorView> {
    private let compressorViewModel: VideoCompressViewModel
    var shouldReloadData = false

    init() {
        let viewModel = VideoCompressViewModel()
        self.compressorViewModel = viewModel
        super.init(rootView: VideoCompressorView(viewModel: viewModel))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        rootView = VideoCompressorView(
            viewModel: compressorViewModel,
            onVideoSelected: { [weak self] video in
                self?.navigateToQualitySelection(video: video)
            }
        )
        
        compressorViewModel.fetchData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        tabBarController?.tabBar.isHidden = false

        if shouldReloadData {
            compressorViewModel.fetchData()
            shouldReloadData = false
        }
    }

    private func navigateToQualitySelection(video: CompressVideoModel) {
        let vc = CompressQualitySelectionHostingController(compressAsset: video)
        vc.dataChangedHandler = { [weak self] in
            self?.shouldReloadData = true
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}
