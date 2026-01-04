//
//  MediaHubView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI
import Photos

struct MediaHubView: View {
    @StateObject private var viewModel = MediaHubViewModel()

    var body: some View {
        ZStack {
            Color.lightBlueDarkGrey
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header with total files info
                    headerView

                    // Media Categories
                    ForEach(viewModel.sections, id: \.title) { section in
                        MediaSectionView(section: section)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Photos & Videos")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            logEvent(Event.MediaScreen.loaded.rawValue, parameter: nil)
            viewModel.fetchAllMediaTypes()
            NotificationCenter.default.addObserver(
                forName: Notification.Name.updateData,
                object: nil,
                queue: .main
            ) { _ in
                viewModel.fetchAllMediaTypes()
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.totalFiles) Files")
                    .font(.headline)
                Text(viewModel.totalSize.formatBytes())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .primaryCell))
        .cornerRadius(15)
    }
}

// MARK: - Media Section View

struct MediaSectionView: View {
    let section: MediaSection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(section.cells, id: \.cellType) { cell in
                    NavigationLink(destination: destinationView(for: cell)) {
                        MediaCategoryCard(cell: cell)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func destinationView(for cell: MediaCellData) -> some View {
        MediaGridContainerView(
            mediaType: cell.cellType,
            title: cell.cellType.rawValue
        )
    }
}

// MARK: - Media Category Card

struct MediaCategoryCard: View {
    let cell: MediaCellData
    @State private var thumbnails: [UIImage] = []

    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail area
            ZStack {
                if thumbnails.isEmpty {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 100)
                        .overlay {
                            Image(systemName: cell.imageName)
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        }
                } else if cell.stackShouldVertical {
                    // Stacked thumbnails for similar/duplicate
                    stackedThumbnails
                } else {
                    // Grid thumbnails for others
                    gridThumbnails
                }
            }
            .frame(height: 100)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16))

            // Info area
            VStack(alignment: .leading, spacing: 4) {
                Text(cell.mainTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                HStack {
                    Text("\(cell.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if cell.size > 0 {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(cell.size.formatBytes())
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(uiColor: .primaryCell))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 16, bottomTrailingRadius: 16, topTrailingRadius: 0))
        }
        .background(Color(uiColor: .primaryCell))
        .cornerRadius(16)
        .onAppear {
            loadThumbnails()
        }
    }

    private var stackedThumbnails: some View {
        ZStack {
            if thumbnails.count > 1 {
                Image(uiImage: thumbnails[1])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 100)
                    .clipped()
                    .offset(x: 10, y: -5)
                    .opacity(0.7)
            }
            if !thumbnails.isEmpty {
                Image(uiImage: thumbnails[0])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 100)
                    .clipped()
            }
        }
    }

    private var gridThumbnails: some View {
        HStack(spacing: 2) {
            ForEach(0..<min(thumbnails.count, 3), id: \.self) { index in
                Image(uiImage: thumbnails[index])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .clipped()
            }
        }
    }

    private func loadThumbnails() {
        Task {
            var images: [UIImage] = []
            for asset in cell.assets.prefix(3) {
                if let image = asset.getImage() {
                    images.append(image)
                }
            }
            await MainActor.run {
                thumbnails = images
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class MediaHubViewModel: ObservableObject {
    @Published var sections: [MediaSection] = []
    @Published var totalFiles: Int = 0
    @Published var totalSize: Int64 = 0

    private let sectionsConfig: [(title: String, cells: [MediaCellType])] = [
        ("Photos", [.duplicatePhoto, .similarPhoto, .otherPhoto]),
        ("Screenshots", [.duplicateScreenshot, .similarScreenshot, .otherScreenshot]),
        ("Videos", [.similarVideos, .screenRecordings, .allVideos])
    ]

    init() {
        // Initialize with empty sections
        sections = sectionsConfig.map { config in
            let cells = config.cells.map { type in
                MediaCellData(
                    mainTitle: type.cell.mainTitle,
                    imageName: type.cell.imageName,
                    cellType: type,
                    count: 0,
                    assets: [],
                    size: 0,
                    stackShouldVertical: type.cell.stackShouldVertical
                )
            }
            return MediaSection(title: config.title, cells: cells)
        }
    }

    func fetchAllMediaTypes() {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            var newSections: [MediaSection] = []
            var totalFiles = 0
            var totalSize: Int64 = 0

            for config in self.sectionsConfig {
                var cells: [MediaCellData] = []

                for type in config.cells {
                    let (count, size, assets) = await self.fetchMediaData(for: type)
                    totalFiles += count
                    totalSize += size

                    cells.append(MediaCellData(
                        mainTitle: type.cell.mainTitle,
                        imageName: type.cell.imageName,
                        cellType: type,
                        count: count,
                        assets: assets,
                        size: size,
                        stackShouldVertical: type.cell.stackShouldVertical
                    ))
                }

                newSections.append(MediaSection(title: config.title, cells: cells))
            }

            await MainActor.run {
                self.sections = newSections
                self.totalFiles = totalFiles
                self.totalSize = totalSize
            }
        }
    }

    private func fetchMediaData(for type: MediaCellType) async -> (count: Int, size: Int64, assets: [PHAsset]) {
        let predicate = getPredicate(mediaType: type)
        let context = CoreDataManager.customContext
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        let dbAssets = CoreDataManager.shared.fetchDBAssets(context: context, predicate: predicate, sortDescriptor: sortDescriptor)

        let size = dbAssets.reduce(Int64(0)) { $0 + $1.size }

        // Get preview assets (up to 5 for thumbnails)
        var previewAssets: [PHAsset] = []
        var subId: UUID?

        for asset in dbAssets {
            switch type {
            case .otherPhoto, .otherScreenshot, .allVideos, .screenRecordings:
                if previewAssets.count >= 5 { break }
            default:
                if previewAssets.count >= 2 { break }
                if previewAssets.count > 0, let subId = subId {
                    if let matchingAsset = dbAssets.first(where: { $0.subGroupId == subId }),
                       let phAsset = matchingAsset.getPHAsset() {
                        previewAssets.append(phAsset)
                        break
                    }
                }
            }

            subId = asset.subGroupId
            if let phAsset = asset.getPHAsset() {
                previewAssets.append(phAsset)
            }
        }

        return (dbAssets.count, size, previewAssets)
    }

    private func getPredicate(mediaType: MediaCellType) -> NSPredicate {
        var assetMediaType: PHAssetCustomMediaType = .photo
        var groupType: PHAssetGroupType = .duplicate

        switch mediaType {
        case .similarPhoto:
            assetMediaType = .photo
            groupType = .similar
        case .duplicatePhoto:
            assetMediaType = .photo
            groupType = .duplicate
        case .otherPhoto:
            assetMediaType = .photo
            groupType = .other
        case .similarScreenshot:
            assetMediaType = .screenshot
            groupType = .similar
        case .duplicateScreenshot:
            assetMediaType = .screenshot
            groupType = .duplicate
        case .otherScreenshot:
            assetMediaType = .screenshot
            groupType = .other
        case .similarVideos:
            assetMediaType = .video
            groupType = .similar
        case .screenRecordings:
            assetMediaType = .screenRecording
            groupType = .all
        case .allVideos:
            assetMediaType = .video
            groupType = .all
        }

        let mediaPredicate = NSPredicate(format: "mediaTypeValue == %@", assetMediaType.rawValue)
        let groupPredicate = NSPredicate(format: "groupTypeValue == %@", groupType.rawValue)
        let isCheckedPredicate = NSPredicate(format: "isChecked == %@", NSNumber(value: true))
        return NSCompoundPredicate(andPredicateWithSubpredicates: [mediaPredicate, groupPredicate, isCheckedPredicate])
    }
}

// MARK: - Models

struct MediaSection {
    let title: String
    var cells: [MediaCellData]
}

struct MediaCellData {
    let mainTitle: String
    let imageName: String
    let cellType: MediaCellType
    var count: Int
    var assets: [PHAsset]
    var size: Int64
    let stackShouldVertical: Bool
}

#Preview {
    NavigationStack {
        MediaHubView()
    }
}
