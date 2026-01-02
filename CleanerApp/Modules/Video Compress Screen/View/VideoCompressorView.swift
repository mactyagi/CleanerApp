//
//  VideoCompressorView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI
import Photos

struct VideoCompressorView: View {
    @StateObject private var viewModel = VideoCompressViewModel()
    @State private var selectedVideo: CompressVideoModel?

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.lightBlueDarkGrey
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("Loading videos...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.compressVideoModel.isEmpty {
                    emptyStateView
                } else {
                    videoGridView
                }
            }
            .navigationTitle("Compressor")
            .navigationDestination(item: $selectedVideo) { video in
                CompressQualityView(compressAsset: video) {
                    viewModel.fetchData()
                }
            }
        }
        .onAppear {
            logEvent(Event.CompressorScreen.loaded.rawValue, parameter: nil)
            if viewModel.compressVideoModel.isEmpty {
                viewModel.fetchData()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Videos Found")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Videos from your library will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Video Grid

    private var videoGridView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerView

                // Grid
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(viewModel.compressVideoModel, id: \.phAsset.localIdentifier) { video in
                        VideoCompressorCell(video: video)
                            .onTapGesture {
                                selectedVideo = video
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Videos \(viewModel.compressVideoModel.count) • \(viewModel.totalSize.convertToFileString())")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Text("Potential savings:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.totalCompressSize.convertToFileString())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

// MARK: - Video Cell

struct VideoCompressorCell: View {
    let video: CompressVideoModel
    @State private var thumbnail: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail
            ZStack {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 140)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 140)
                        .overlay {
                            ProgressView()
                        }
                }

                // Play icon overlay
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.8))
            }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16))

            // Size info
            VStack(spacing: 4) {
                HStack {
                    Text("Now:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(video.originalSize.convertToFileString())
                        .font(.caption)
                        .fontWeight(.medium)
                }

                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(video.reduceSize.convertToFileString())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(uiColor: .primaryCell))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 16, bottomTrailingRadius: 16, topTrailingRadius: 0))
        }
        .background(Color(uiColor: .primaryCell))
        .cornerRadius(20)
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

// MARK: - Make CompressVideoModel Identifiable & Hashable for navigation

extension CompressVideoModel: Identifiable, Hashable {
    var id: String { phAsset.localIdentifier }

    static func == (lhs: CompressVideoModel, rhs: CompressVideoModel) -> Bool {
        lhs.phAsset.localIdentifier == rhs.phAsset.localIdentifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(phAsset.localIdentifier)
    }
}

#Preview {
    VideoCompressorView()
}
