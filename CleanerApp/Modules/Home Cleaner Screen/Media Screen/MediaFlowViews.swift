//
//  MediaFlowViews.swift
//  CleanerApp
//
//  Pure SwiftUI views for Media navigation flow
//

import SwiftUI
import Photos
import Combine

// MARK: - Media Flow View (Pure SwiftUI)
struct MediaFlowView: View {
    @ObservedObject var viewModel: MediaViewModel
    @Binding var path: NavigationPath
    
    var body: some View {
        MediaScreenView(
            dataSource: viewModel.dataSource,
            totalFiles: viewModel.totalFiles,
            totalSize: viewModel.totalSize,
            onCellTapped: { cell in
                if cell.cellType.groupType == .other {
                    path.append(MediaDestination.otherPhotos(cell.cellType))
                } else {
                    path.append(MediaDestination.baseView(cell.cellType))
                }
            },
            onBackTapped: {
                if !path.isEmpty {
                    path.removeLast()
                }
            }
        )
        .navigationTitle("Media Cleaner")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchAllMediaType()
        }
    }
}

// MARK: - Media Navigation Destinations
enum MediaDestination: Hashable {
    case baseView(MediaCellType)
    case otherPhotos(MediaCellType)
}

// MARK: - Base View (Pure SwiftUI for grouped photos)
struct BaseViewSwiftUI: View {
    let predicate: NSPredicate
    let groupType: PHAssetGroupType
    let type: MediaCellType
    
    @StateObject private var viewModelWrapper: BaseViewModelWrapperSwiftUI
    @State private var selectedIndexPaths: Set<IndexPath> = []
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    init(predicate: NSPredicate, groupType: PHAssetGroupType, type: MediaCellType) {
        self.predicate = predicate
        self.groupType = groupType
        self.type = type
        
        let viewModel = BaseViewModel(predicate: predicate, groupType: groupType, type: type)
        _viewModelWrapper = StateObject(wrappedValue: BaseViewModelWrapperSwiftUI(viewModel: viewModel))
    }
    
    var body: some View {
        BaseView(
            viewModelWrapper: BaseViewModelWrapper(viewModel: viewModelWrapper.viewModel),
            selectedIndexPaths: $selectedIndexPaths,
            onDelete: {
                showDeleteAlert = true
            }
        )
        .navigationTitle(type.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !viewModelWrapper.viewModel.assetRows.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModelWrapper.viewModel.isAllSelected.toggle()
                        if viewModelWrapper.viewModel.isAllSelected {
                            viewModelWrapper.viewModel.selectAll()
                        } else {
                            viewModelWrapper.viewModel.deselectAll()
                        }
                        selectedIndexPaths = viewModelWrapper.viewModel.selectedIndexPath
                    }) {
                        Text(viewModelWrapper.viewModel.isAllSelected ? "Deselect All" : "Select All")
                            .font(.system(size: 15, weight: .medium))
                    }
                }
            }
        }
        .alert("Delete Photos", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                viewModelWrapper.viewModel.selectedIndexPath = selectedIndexPaths
                viewModelWrapper.viewModel.deleteAllSelected()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(selectedIndexPaths.count) items?")
        }
        .overlay {
            if viewModelWrapper.viewModel.showLoader {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .onAppear {
            selectedIndexPaths = viewModelWrapper.viewModel.selectedIndexPath
        }
    }
}

// MARK: - ViewModel wrapper for SwiftUI state management
class BaseViewModelWrapperSwiftUI: ObservableObject {
    let viewModel: BaseViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: BaseViewModel) {
        self.viewModel = viewModel
        
        viewModel.$selectedIndexPath
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        viewModel.$showLoader
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        viewModel.$isAllSelected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Other Photos View (Pure SwiftUI for "Other" photos swipe)
struct OtherPhotosSwiftUI: View {
    let predicate: NSPredicate?
    let cellType: MediaCellType
    
    @State private var assets: [DBAsset] = []
    @State private var selectedIndexPaths: Set<IndexPath> = []
    @State private var isLoading = true
    @State private var showDeleteAlert = false
    @State private var previewTarget: PreviewTarget?
    @Environment(\.dismiss) private var dismiss
    
    private var selectedCount: Int {
        selectedIndexPaths.count
    }
    
    private var selectedSize: Int64 {
        selectedIndexPaths.reduce(0) { sum, indexPath in
            guard indexPath.row < assets.count else { return sum }
            return sum + assets[indexPath.row].size
        }
    }

    private var totalSize: Int64 {
        assets.reduce(0) { $0 + $1.size }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if isLoading {
                ProgressView("Loading...")
            } else if assets.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Photos Found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Size subtitle
                        Text("Photos: \(assets.count) • \(totalSize.formatBytes())")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        // 2-column vertical grid
                        VerticalGridSectionView(
                            assets: assets,
                            section: 0,
                            selectedIndexPaths: $selectedIndexPaths,
                            onPreview: { row in
                                previewTarget = PreviewTarget(section: 0, index: row)
                            }
                        )
                    }
                    .padding(.bottom, 100)
                }
                .fullScreenCover(item: $previewTarget) { target in
                    if target.index < assets.count {
                        ImagePreviewView(
                            assets: assets,
                            initialIndex: target.index,
                            selectedIndexPaths: $selectedIndexPaths,
                            section: 0,
                            groupType: .other,
                            isPresented: Binding(
                                get: { previewTarget != nil },
                                set: { if !$0 { previewTarget = nil } }
                            )
                        )
                    }
                }
            }
            
            // Delete button
            if selectedCount > 0 {
                Button(action: { showDeleteAlert = true }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete \(selectedCount) items")
                            .fontWeight(.semibold)
                        Text("• \(selectedSize.convertToFileString())")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color.red))
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: selectedCount)
        .navigationTitle(cellType.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !assets.isEmpty {
                    Button(action: toggleSelectAll) {
                        Text(isAllSelected ? "Deselect All" : "Select All")
                            .font(.system(size: 15, weight: .medium))
                    }
                }
            }
        }
        .alert("Delete Photos", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteSelectedPhotos()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(selectedCount) photos?")
        }
        .onAppear {
            loadAssets()
        }
    }
    
    private var isAllSelected: Bool {
        guard !assets.isEmpty else { return false }
        for row in 0..<assets.count {
            if !selectedIndexPaths.contains(IndexPath(row: row, section: 0)) {
                return false
            }
        }
        return true
    }

    private func toggleSelectAll() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if isAllSelected {
            selectedIndexPaths.removeAll()
        } else {
            for row in 0..<assets.count {
                selectedIndexPaths.insert(IndexPath(row: row, section: 0))
            }
        }
    }

    private func loadAssets() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let context = CoreDataManager.shared.persistentContainer.viewContext
            let fetchedAssets = CoreDataManager.shared.fetchDBAssets(context: context, predicate: predicate)
            DispatchQueue.main.async {
                self.assets = fetchedAssets
                self.isLoading = false
            }
        }
    }
    
    private func deleteSelectedPhotos() {
        let assetIds = selectedIndexPaths.compactMap { indexPath -> String? in
            guard indexPath.row < assets.count else { return nil }
            return assets[indexPath.row].assetId
        }
        
        let assetsToDelete = selectedIndexPaths.compactMap { indexPath -> DBAsset? in
            guard indexPath.row < assets.count else { return nil }
            return assets[indexPath.row]
        }
        
        PHAssetManager.deleteAssetsById(assetIds: assetIds) { isComplete, error in
            if isComplete {
                assetsToDelete.forEach { asset in
                    CoreDataManager.shared.deleteAsset(asset: asset)
                }
                DispatchQueue.main.async {
                    selectedIndexPaths.removeAll()
                    loadAssets()
                }
            }
        }
    }
}
