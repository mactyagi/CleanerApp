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
        .navigationTitle("Media")
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(viewModelWrapper.viewModel.isAllSelected ? "Deselect All" : "Select All") {
                    viewModelWrapper.viewModel.isAllSelected.toggle()
                    if viewModelWrapper.viewModel.isAllSelected {
                        viewModelWrapper.viewModel.selectAll()
                    } else {
                        viewModelWrapper.viewModel.deselectAll()
                    }
                    selectedIndexPaths = viewModelWrapper.viewModel.selectedIndexPath
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
                OtherPhotosSwipeContentView(
                    assets: assets,
                    selectedIndexPaths: $selectedIndexPaths,
                    section: 0
                )
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
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Other Photos Swipe Content View
struct OtherPhotosSwipeContentView: View {
    let assets: [DBAsset]
    @Binding var selectedIndexPaths: Set<IndexPath>
    let section: Int
    
    @State private var currentIndex: Int = 0
    @State private var offset: CGSize = .zero
    @State private var showPreview = false
    @State private var previewIndex = 0
    
    private var deletedCount: Int {
        selectedIndexPaths.filter { $0.section == section }.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(currentIndex) / \(assets.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("\(deletedCount) marked for deletion")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                if currentIndex > 0 {
                    Button(action: undoLast) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Undo")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
            
            if currentIndex < assets.count {
                // Card stack
                ZStack {
                    ForEach(0..<min(3, assets.count - currentIndex), id: \.self) { index in
                        let cardIndex = currentIndex + (2 - index)
                        if cardIndex < assets.count && cardIndex > currentIndex {
                            SwipeCard(
                                asset: assets[cardIndex],
                                onPreview: {
                                    previewIndex = cardIndex
                                    showPreview = true
                                }
                            )
                            .scaleEffect(1 - CGFloat(2 - index) * 0.05)
                            .offset(y: CGFloat(2 - index) * 8)
                            .allowsHitTesting(false)
                        }
                    }
                    
                    SwipeCard(
                        asset: assets[currentIndex],
                        onPreview: {
                            previewIndex = currentIndex
                            showPreview = true
                        }
                    )
                    .offset(offset)
                    .rotationEffect(.degrees(Double(offset.width / 20)))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = value.translation
                            }
                            .onEnded { value in
                                handleSwipeEnd(value: value)
                            }
                    )
                    .overlay(swipeOverlay)
                }
                .frame(height: 400)
                
                // Action buttons
                HStack(spacing: 40) {
                    Button(action: swipeLeft) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 64, height: 64)
                            Circle()
                                .stroke(Color.red, lineWidth: 2)
                                .frame(width: 64, height: 64)
                            Image(systemName: "trash.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: {
                        previewIndex = currentIndex
                        showPreview = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 50, height: 50)
                            Image(systemName: "eye.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: swipeRight) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 64, height: 64)
                            Circle()
                                .stroke(Color.green, lineWidth: 2)
                                .frame(width: 64, height: 64)
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.top, 8)
                
                HStack(spacing: 40) {
                    Text("Delete")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    Spacer()
                    Text("Keep")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 50)
                
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text("All Done!")
                        .font(.title2.bold())
                    Text("\(deletedCount) photos marked for deletion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: resetCards) {
                        Text("Review Again")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Capsule().stroke(Color.blue, lineWidth: 1))
                    }
                    .padding(.top, 8)
                }
                .frame(height: 400)
            }
            
            Spacer()
        }
        .padding(.vertical)
        .fullScreenCover(isPresented: $showPreview) {
            if previewIndex < assets.count {
                PhotoPreviewView(asset: assets[previewIndex], isPresented: $showPreview)
            }
        }
    }
    
    private var swipeOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.green, lineWidth: 4)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.green.opacity(0.2))
                )
                .overlay(
                    Text("KEEP")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.green)
                        .rotationEffect(.degrees(-15))
                )
                .opacity(offset.width > 50 ? min(Double(offset.width - 50) / 100, 1) : 0)
            
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.red, lineWidth: 4)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.red.opacity(0.2))
                )
                .overlay(
                    Text("DELETE")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.red)
                        .rotationEffect(.degrees(15))
                )
                .opacity(offset.width < -50 ? min(Double(-offset.width - 50) / 100, 1) : 0)
        }
    }
    
    private func handleSwipeEnd(value: DragGesture.Value) {
        let threshold: CGFloat = 100
        
        if value.translation.width > threshold {
            swipeRight()
        } else if value.translation.width < -threshold {
            swipeLeft()
        } else {
            withAnimation(.spring()) {
                offset = .zero
            }
        }
    }
    
    private func swipeRight() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation(.easeOut(duration: 0.3)) {
            offset = CGSize(width: 500, height: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentIndex += 1
            offset = .zero
        }
    }
    
    private func swipeLeft() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let indexPath = IndexPath(row: currentIndex, section: section)
        selectedIndexPaths.insert(indexPath)
        
        withAnimation(.easeOut(duration: 0.3)) {
            offset = CGSize(width: -500, height: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentIndex += 1
            offset = .zero
        }
    }
    
    private func undoLast() {
        guard currentIndex > 0 else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        currentIndex -= 1
        let indexPath = IndexPath(row: currentIndex, section: section)
        selectedIndexPaths.remove(indexPath)
    }
    
    private func resetCards() {
        currentIndex = 0
        selectedIndexPaths = selectedIndexPaths.filter { $0.section != section }
    }
}
