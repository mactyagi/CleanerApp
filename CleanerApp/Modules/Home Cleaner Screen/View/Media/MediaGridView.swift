//
//  MediaGridView.swift
//  CleanerApp
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI
import Photos

struct MediaGridContainerView: View {
    let mediaType: MediaCellType
    let title: String

    @StateObject private var viewModel: MediaGridViewModel

    init(mediaType: MediaCellType, title: String) {
        self.mediaType = mediaType
        self.title = title
        _viewModel = StateObject(wrappedValue: MediaGridViewModel(mediaType: mediaType))
    }

    var body: some View {
        ZStack {
            Color.lightBlueDarkGrey
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("Loading...")
            } else if viewModel.sections.isEmpty {
                emptyStateView
            } else {
                MediaGridView(viewModel: viewModel)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(viewModel.isAllSelected ? "Deselect All" : "Select All") {
                    viewModel.toggleSelectAll()
                }
                .disabled(viewModel.sections.isEmpty)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !viewModel.selectedAssets.isEmpty {
                deleteButtonView
            }
        }
        .onAppear {
            viewModel.logScreenLoaded()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No \(title)")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Items will appear here once found")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var deleteButtonView: some View {
        VStack(spacing: 8) {
            Text("Delete \(viewModel.selectedAssets.count) Selected")
                .font(.headline)
                .foregroundColor(.white)

            Text("Clear: \(viewModel.selectedSize.formatBytes())")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .cornerRadius(20)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .onTapGesture {
            viewModel.deleteSelected()
        }
    }
}

// MARK: - Media Grid View

struct MediaGridView: View {
    @ObservedObject var viewModel: MediaGridViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                ForEach(Array(viewModel.sections.enumerated()), id: \.offset) { sectionIndex, section in
                    Section {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(Array(section.assets.enumerated()), id: \.offset) { assetIndex, asset in
                                MediaGridCell(
                                    asset: asset,
                                    isSelected: viewModel.isSelected(section: sectionIndex, row: assetIndex),
                                    onTap: {
                                        viewModel.toggleSelection(section: sectionIndex, row: assetIndex)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    } header: {
                        if viewModel.showSectionHeaders {
                            SectionHeaderView(
                                title: "\(viewModel.groupType.rawValue.capitalized): \(section.assets.count)",
                                isAllSelected: viewModel.isSectionAllSelected(sectionIndex),
                                onSelectAll: {
                                    viewModel.toggleSectionSelection(sectionIndex)
                                }
                            )
                        }
                    }
                }
            }
            .padding(.bottom, 100) // Space for delete button
        }
    }
}

// MARK: - Section Header View

struct SectionHeaderView: View {
    let title: String
    let isAllSelected: Bool
    let onSelectAll: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Spacer()

            Button(action: onSelectAll) {
                Text(isAllSelected ? "Deselect" : "Select All")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.lightBlueDarkGrey)
    }
}

// MARK: - Media Grid Cell

struct MediaGridCell: View {
    let asset: DBAsset
    let isSelected: Bool
    let onTap: () -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 150)
                    .overlay {
                        ProgressView()
                    }
            }

            // Selection indicator
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : Color.white.opacity(0.8))
                    .frame(width: 24, height: 24)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(8)

            // Size label
            VStack {
                Spacer()
                HStack {
                    Text(asset.size.formatBytes())
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(4)
                    Spacer()
                }
                .padding(6)
            }
        }
        .cornerRadius(12)
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }
        .contextMenu {
            if let phAsset = asset.getPHAsset(), let image = phAsset.getImage() {
                Button("Preview") {
                    // Preview action handled by context menu preview
                }
            }
        } preview: {
            if let phAsset = asset.getPHAsset(), let image = phAsset.getImage() {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Text("Loading...")
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        Task {
            if let phAsset = asset.getPHAsset(),
               let image = phAsset.getImage() {
                await MainActor.run {
                    thumbnail = image
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class MediaGridViewModel: ObservableObject {
    @Published var sections: [MediaGridSection] = []
    @Published var selectedAssets: Set<IndexPath> = []
    @Published var isAllSelected: Bool = true
    @Published var isLoading: Bool = true
    @Published var showLoader: Bool = false

    let mediaType: MediaCellType
    let groupType: PHAssetGroupType

    var showSectionHeaders: Bool {
        groupType != .other && groupType != .all
    }

    var selectedSize: Int64 {
        selectedAssets.reduce(Int64(0)) { total, indexPath in
            guard indexPath.section < sections.count,
                  indexPath.row < sections[indexPath.section].assets.count else {
                return total
            }
            return total + sections[indexPath.section].assets[indexPath.row].size
        }
    }

    init(mediaType: MediaCellType) {
        self.mediaType = mediaType
        self.groupType = mediaType.groupType
        fetchData()
    }

    func fetchData() {
        isLoading = true

        let mediaType = self.mediaType
        let groupType = self.groupType

        Task.detached(priority: .userInitiated) {
            let predicate = Self.buildPredicate(for: mediaType)
            let context = CoreDataManager.customContext
            let dbAssets = CoreDataManager.shared.fetchDBAssets(context: context, predicate: predicate)

            // Group by subGroupId for similar/duplicate views
            var newSections: [MediaGridSection] = []

            if groupType == .other || groupType == .all {
                // Single section for "other" and "all" types
                let sortedAssets = dbAssets.sorted { ($0.creationDate ?? Date()) > ($1.creationDate ?? Date()) }
                newSections = [MediaGridSection(subGroupId: nil, assets: sortedAssets)]
            } else {
                // Group by subGroupId
                let grouped = Dictionary(grouping: dbAssets) { $0.subGroupId }
                for (subId, assets) in grouped {
                    let sortedAssets = assets.sorted { ($0.creationDate ?? Date()) > ($1.creationDate ?? Date()) }
                    newSections.append(MediaGridSection(subGroupId: subId, assets: sortedAssets))
                }
                // Sort sections by first asset's creation date
                newSections.sort { ($0.assets.first?.creationDate ?? Date()) > ($1.assets.first?.creationDate ?? Date()) }
            }

            await MainActor.run { [weak self] in
                self?.sections = newSections
                self?.isLoading = false
                self?.selectAllByDefault()
            }
        }
    }

    private nonisolated static func buildPredicate(for mediaType: MediaCellType) -> NSPredicate {
        var assetMediaType: PHAssetCustomMediaType = .photo
        var groupTypeValue: PHAssetGroupType = .duplicate

        switch mediaType {
        case .similarPhoto:
            assetMediaType = .photo
            groupTypeValue = .similar
        case .duplicatePhoto:
            assetMediaType = .photo
            groupTypeValue = .duplicate
        case .otherPhoto:
            assetMediaType = .photo
            groupTypeValue = .other
        case .similarScreenshot:
            assetMediaType = .screenshot
            groupTypeValue = .similar
        case .duplicateScreenshot:
            assetMediaType = .screenshot
            groupTypeValue = .duplicate
        case .otherScreenshot:
            assetMediaType = .screenshot
            groupTypeValue = .other
        case .similarVideos:
            assetMediaType = .video
            groupTypeValue = .similar
        case .screenRecordings:
            assetMediaType = .screenRecording
            groupTypeValue = .all
        case .allVideos:
            assetMediaType = .video
            groupTypeValue = .all
        }

        let mediaPredicate = NSPredicate(format: "mediaTypeValue == %@", assetMediaType.rawValue)
        let groupPredicate = NSPredicate(format: "groupTypeValue == %@", groupTypeValue.rawValue)
        let isCheckedPredicate = NSPredicate(format: "isChecked == %@", NSNumber(value: true))
        return NSCompoundPredicate(andPredicateWithSubpredicates: [mediaPredicate, groupPredicate, isCheckedPredicate])
    }

    // MARK: - Selection Logic

    private func selectAllByDefault() {
        var newSelection: Set<IndexPath> = []

        for (sectionIndex, section) in sections.enumerated() {
            for (assetIndex, _) in section.assets.enumerated() {
                // For similar/duplicate, skip first item in each group (the "original")
                if groupType == .similar || groupType == .duplicate {
                    if assetIndex > 0 {
                        newSelection.insert(IndexPath(row: assetIndex, section: sectionIndex))
                    }
                } else {
                    // For "other" and "all", select everything
                    newSelection.insert(IndexPath(row: assetIndex, section: sectionIndex))
                }
            }
        }

        selectedAssets = newSelection
        checkIfAllSelected()
    }

    func isSelected(section: Int, row: Int) -> Bool {
        selectedAssets.contains(IndexPath(row: row, section: section))
    }

    func toggleSelection(section: Int, row: Int) {
        let indexPath = IndexPath(row: row, section: section)
        if selectedAssets.contains(indexPath) {
            selectedAssets.remove(indexPath)
        } else {
            selectedAssets.insert(indexPath)
        }
        checkIfAllSelected()
    }

    func toggleSelectAll() {
        if isAllSelected {
            selectedAssets.removeAll()
        } else {
            selectAllByDefault()
        }
        isAllSelected.toggle()
    }

    func isSectionAllSelected(_ sectionIndex: Int) -> Bool {
        guard sectionIndex < sections.count else { return false }
        let section = sections[sectionIndex]

        let startIndex = (groupType == .similar || groupType == .duplicate) ? 1 : 0

        for assetIndex in startIndex..<section.assets.count {
            if !selectedAssets.contains(IndexPath(row: assetIndex, section: sectionIndex)) {
                return false
            }
        }
        return true
    }

    func toggleSectionSelection(_ sectionIndex: Int) {
        guard sectionIndex < sections.count else { return }
        let section = sections[sectionIndex]

        let isCurrentlyAllSelected = isSectionAllSelected(sectionIndex)
        let startIndex = (groupType == .similar || groupType == .duplicate) ? 1 : 0

        for assetIndex in startIndex..<section.assets.count {
            let indexPath = IndexPath(row: assetIndex, section: sectionIndex)
            if isCurrentlyAllSelected {
                selectedAssets.remove(indexPath)
            } else {
                selectedAssets.insert(indexPath)
            }
        }

        checkIfAllSelected()
    }

    private func checkIfAllSelected() {
        for (sectionIndex, _) in sections.enumerated() {
            if !isSectionAllSelected(sectionIndex) {
                isAllSelected = false
                return
            }
        }
        isAllSelected = true
    }

    // MARK: - Delete

    func deleteSelected() {
        showLoader = true

        var deleteableAssetIds: [String] = []
        var deleteableAssets: [DBAsset] = []

        for indexPath in selectedAssets {
            guard indexPath.section < sections.count,
                  indexPath.row < sections[indexPath.section].assets.count else {
                continue
            }

            let asset = sections[indexPath.section].assets[indexPath.row]
            if let assetId = asset.assetId {
                deleteableAssetIds.append(assetId)
            }
            deleteableAssets.append(asset)
        }

        PHAssetManager.deleteAssetsById(assetIds: deleteableAssetIds) { [weak self] isComplete, error in
            guard let self = self else { return }

            if isComplete {
                deleteableAssets.forEach { asset in
                    CoreDataManager.shared.deleteAsset(asset: asset)
                }
                CoreDataPHAssetManager.shared.removeSingleElementFromCoreData(context: CoreDataManager.customContext)

                Task { @MainActor in
                    self.fetchData()
                    self.logDeleteEvent(count: deleteableAssets.count)
                }
            }

            Task { @MainActor in
                self.showLoader = false
            }
        }
    }

    // MARK: - Analytics

    func logScreenLoaded() {
        switch mediaType {
        case .similarPhoto:
            logEvent(Event.SimilarPhotosScreen.loaded.rawValue, parameter: nil)
        case .duplicatePhoto:
            logEvent(Event.DuplicatePhotosScreen.loaded.rawValue, parameter: nil)
        case .otherPhoto:
            logEvent(Event.OtherPhotosScreen.loaded.rawValue, parameter: nil)
        case .similarScreenshot:
            logEvent(Event.SimilarScreenshotScreen.loaded.rawValue, parameter: nil)
        case .duplicateScreenshot:
            logEvent(Event.DuplicateScreenshotScreen.loaded.rawValue, parameter: nil)
        case .otherScreenshot:
            logEvent(Event.OtherScreenshotScreen.loaded.rawValue, parameter: nil)
        default:
            break
        }
    }

    private func logDeleteEvent(count: Int) {
        switch mediaType {
        case .similarPhoto:
            logEvent(Event.SimilarPhotosScreen.deletedPhotos.rawValue, parameter: ["count": count])
        case .duplicatePhoto:
            logEvent(Event.DuplicatePhotosScreen.deletedPhotos.rawValue, parameter: ["count": count])
        case .otherPhoto:
            logEvent(Event.OtherPhotosScreen.deletedPhotos.rawValue, parameter: ["count": count])
        case .similarScreenshot:
            logEvent(Event.SimilarScreenshotScreen.deletedScreenshot.rawValue, parameter: ["count": count])
        case .duplicateScreenshot:
            logEvent(Event.DuplicateScreenshotScreen.deletedScreenshot.rawValue, parameter: ["count": count])
        case .otherScreenshot:
            logEvent(Event.OtherScreenshotScreen.deletedScreenshot.rawValue, parameter: ["count": count])
        default:
            break
        }
    }
}

// MARK: - Models

struct MediaGridSection {
    let subGroupId: UUID?
    var assets: [DBAsset]
}

#Preview {
    NavigationStack {
        MediaGridContainerView(mediaType: .similarPhoto, title: "Similar Photos")
    }
}
