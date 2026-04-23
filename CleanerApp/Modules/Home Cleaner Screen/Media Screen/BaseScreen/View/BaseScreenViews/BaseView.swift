//
//  BaseView.swift
//  CleanerApp
//
//  SwiftUI implementation for Photo Grid Detail Screen
//

import SwiftUI
import Photos
import Combine

// MARK: - Preview Target (used by fullScreenCover item binding)
struct PreviewTarget: Identifiable {
    let id = UUID()
    let section: Int
    let index: Int
}

// MARK: - Base View (Production)
struct BaseView: View {
    @ObservedObject var viewModel: BaseViewModel
//    @Binding var selectedIndexPaths: Set<IndexPath>
    @State private var previewTarget: PreviewTarget?
    var onDelete: (() -> Void)?

//    private var viewModel: BaseViewModel { viewModelWrapper.viewModel }

    var selectedCount: Int { viewModel.selectedIndexPath.count }
    var selectedSize: Int64 {
        viewModel.selectedIndexPath.reduce(0) { sum, indexPath in
            guard indexPath.section < viewModel.assetRows.count,
                  indexPath.row < viewModel.assetRows[indexPath.section].count else { return sum }
            return sum + viewModel.assetRows[indexPath.section][indexPath.row].size
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.lightBlueDarkGrey
                .ignoresSafeArea()

            
            if !viewModel.isLoading && (viewModel.assetRows.isEmpty || !viewModel.assetRows.contains(where: { !$0.isEmpty })) {
                MediaEmptyStateView(mediaType: viewModel.type, groupType: viewModel.groupType)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        // Size subtitle
                        Text(viewModel.sizeLabel)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        // Grouped Sections
                        ForEach(viewModel.assetRows.indices, id: \.self) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                // Section Header
                                HStack {
                                    if viewModel.groupType == .other {
                                        Text("\(viewModel.assetRows[section].count) items")
                                            .font(.headline)
                                    } else {
                                        Text("\(viewModel.groupType.rawValue.capitalized): \(viewModel.assetRows[section].count)")
                                            .font(.headline)
                                    }
                                    Spacer()
                                    Button(action: {
                                        toggleSelectAllInSection(section)
                                    }) {
                                        Text(isAllSelectedInSection(section) ? "Deselect All" : "Select All")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(isAllSelectedInSection(section) ? .red : .blue)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(isAllSelectedInSection(section) ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                            )
                                    }
                                }
                                .padding(.horizontal)

                                // Photos in section
                                if viewModel.groupType == .other {
                                    VerticalGridSectionView(
                                        assets: viewModel.assetRows[section],
                                        section: section,
                                        selectedIndexPaths: $viewModel.selectedIndexPath,
                                        onPreview: { row in
                                            previewTarget = PreviewTarget(section: section, index: row)
                                        }
                                    )
                                } else {
                                    PhotoSectionView(
                                        assets: viewModel.assetRows[section],
                                        section: section,
                                        groupType: viewModel.groupType,
                                        selectedIndexPaths: $viewModel.selectedIndexPath,
                                        onPreview: { row in
                                            previewTarget = PreviewTarget(section: section, index: row)
                                        }
                                    )
                                }
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("offWhiteAndGrayColor"))
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 100)
                }

                // Floating Delete Button
                if selectedCount > 0 {
                    deleteButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(), value: selectedCount)
        .fullScreenCover(item: $previewTarget) { target in
            if target.section < viewModel.assetRows.count {
                ImagePreviewView(
                    assets: viewModel.assetRows[target.section],
                    initialIndex: target.index,
                    selectedIndexPaths: $viewModel.selectedIndexPath,
                    section: target.section,
                    groupType: viewModel.groupType,
                    isPresented: Binding(
                        get: { previewTarget != nil },
                        set: { if !$0 { previewTarget = nil } }
                    )
                )
            }
        }
    }

    private var deleteButton: some View {
        Button(action: { onDelete?() }) {
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
    }

    private func toggleSelection(_ indexPath: IndexPath) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if viewModel.selectedIndexPath.contains(indexPath) {
            viewModel.selectedIndexPath.remove(indexPath)
        } else {
            viewModel.selectedIndexPath.insert(indexPath)
        }
    }

    private func isAllSelectedInSection(_ section: Int) -> Bool {
        let sectionItems = viewModel.assetRows[section]
        for row in 0..<sectionItems.count {
            // Skip first item (best photo) for non-other groups
            if row == 0 && viewModel.groupType != .other { continue }
            let indexPath = IndexPath(row: row, section: section)
            if !viewModel.selectedIndexPath.contains(indexPath) {
                return false
            }
        }
        return true
    }

    private func toggleSelectAllInSection(_ section: Int) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if isAllSelectedInSection(section) {
            // Deselect all in section
            for row in 0..<viewModel.assetRows[section].count {
                viewModel.selectedIndexPath.remove(IndexPath(row: row, section: section))
            }
        } else {
            // Select all in section (except best photo)
            for row in 0..<viewModel.assetRows[section].count {
                if row > 0 || viewModel.groupType == .other {
                    viewModel.selectedIndexPath.insert(IndexPath(row: row, section: section))
                }
            }
        }
    }
}

// MARK: - Photo Section View
struct PhotoSectionView: View {
    let assets: [DBAsset]
    let section: Int
    let groupType: PHAssetGroupType
    @Binding var selectedIndexPaths: Set<IndexPath>
    var onPreview: (Int) -> Void

    private let spacing: CGFloat = 8
    private let horizontalPadding: CGFloat = 16

    // Calculate fixed square size based on screen width (fit 2 photos with peek of 3rd)
    private var photoSize: CGFloat {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        if isIPad {
            return 150
        }
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - (horizontalPadding * 2)
        // Size to fit 2 photos with spacing and show peek of 3rd
        let size = (availableWidth - spacing) / 2.2
        return floor(size) // Round down for clean pixels
    }

    var body: some View {

        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: spacing) {
                ForEach(assets.indices, id: \.self) { row in
                    cellView(row: row)
                        .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, horizontalPadding)
        }
        .frame(height: photoSize)
    }

    @ViewBuilder
    private func cellView(row: Int) -> some View {
        let indexPath = IndexPath(row: row, section: section)
        let isSelected = selectedIndexPaths.contains(indexPath)

        BasePhotoCell(
            asset: assets[row],
            isSelected: isSelected,
            isFirst: row == 0 && groupType != .other,
            size: photoSize,
            onSelect: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()

                if selectedIndexPaths.contains(indexPath) {
                    selectedIndexPaths.remove(indexPath)
                } else {
                    selectedIndexPaths.insert(indexPath)
                }
            },
            onPreview: {
                onPreview(row)
            }
        )
    }
}


var count = 0
