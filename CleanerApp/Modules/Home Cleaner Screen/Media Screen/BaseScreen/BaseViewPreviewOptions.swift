//
//  BaseViewPreviewOptions.swift
//  CleanerApp
//
//  Preview Options Demo for Photo Preview Feature
//

import SwiftUI
import UIKit
import Photos
import Combine

// MARK: - Option 1: Tap to Preview, Long Press to Select
struct PreviewOption1View: View {
    @ObservedObject var viewModelWrapper: BaseViewModelWrapper
    @Binding var selectedIndexPaths: Set<IndexPath>
    @State private var previewAsset: DBAsset?
    @State private var showPreview = false
    var onDelete: (() -> Void)?

    private var viewModel: BaseViewModel { viewModelWrapper.viewModel }

    var selectedCount: Int { selectedIndexPaths.count }
    var selectedSize: Int64 {
        selectedIndexPaths.reduce(0) { sum, indexPath in
            guard indexPath.section < viewModel.assetRows.count,
                  indexPath.row < viewModel.assetRows[indexPath.section].count else { return sum }
            return sum + viewModel.assetRows[indexPath.section][indexPath.row].size
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.type.rawValue)
                            .font(.largeTitle.bold())
                        Text(viewModel.sizeLabel)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Tap to preview • Long press to select")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)

                    // Grouped Sections
                    ForEach(viewModel.assetRows.indices, id: \.self) { section in
                        sectionView(section: section)
                    }
                }
                .padding(.top)
                .padding(.bottom, 100)
            }

            // Floating Delete Button
            if selectedCount > 0 {
                deleteButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: selectedCount)
        .fullScreenCover(isPresented: $showPreview) {
            if let asset = previewAsset {
                FullScreenPreview(asset: asset, isPresented: $showPreview)
            }
        }
    }

    private func sectionView(section: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.groupType != .other {
                HStack {
                    Text("Group \(section + 1)")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.assetRows[section].count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Select All") {
                        selectAllInSection(section)
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.assetRows[section].indices, id: \.self) { row in
                        let indexPath = IndexPath(row: row, section: section)
                        let isSelected = selectedIndexPaths.contains(indexPath)
                        Option1Cell(
                            asset: viewModel.assetRows[section][row],
                            isSelected: isSelected,
                            isFirst: row == 0 && viewModel.groupType != .other,
                            onTap: {
                                // Tap to preview
                                previewAsset = viewModel.assetRows[section][row]
                                showPreview = true
                            },
                            onLongPress: {
                                // Long press to select
                                toggleSelection(indexPath)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.systemBackground)))
        .padding(.horizontal)
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
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if selectedIndexPaths.contains(indexPath) {
            selectedIndexPaths.remove(indexPath)
        } else {
            selectedIndexPaths.insert(indexPath)
        }
    }

    private func selectAllInSection(_ section: Int) {
        for row in 0..<viewModel.assetRows[section].count {
            if row > 0 || viewModel.groupType == .other {
                selectedIndexPaths.insert(IndexPath(row: row, section: section))
            }
        }
    }
}

struct Option1Cell: View {
    let asset: DBAsset
    let isSelected: Bool
    let isFirst: Bool
    var onTap: () -> Void
    var onLongPress: () -> Void

    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .bottom) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 150, height: 150)
            }

            LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                .frame(height: 40)

            HStack {
                if isFirst {
                    Text("Best")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .cornerRadius(4)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
        .onTapGesture { onTap() }
        .onLongPressGesture { onLongPress() }
        .onAppear { loadImage() }
    }

    private func loadImage() {
        asset.getPHAsset()?.getImage { img in
            DispatchQueue.main.async { self.image = img }
        }
    }
}

// MARK: - Option 2: Preview Icon on Each Cell
struct PreviewOption2View: View {
    @ObservedObject var viewModelWrapper: BaseViewModelWrapper
    @Binding var selectedIndexPaths: Set<IndexPath>
    @State private var previewAsset: DBAsset?
    @State private var showPreview = false
    var onDelete: (() -> Void)?

    private var viewModel: BaseViewModel { viewModelWrapper.viewModel }

    var selectedCount: Int { selectedIndexPaths.count }
    var selectedSize: Int64 {
        selectedIndexPaths.reduce(0) { sum, indexPath in
            guard indexPath.section < viewModel.assetRows.count,
                  indexPath.row < viewModel.assetRows[indexPath.section].count else { return sum }
            return sum + viewModel.assetRows[indexPath.section][indexPath.row].size
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.type.rawValue)
                            .font(.largeTitle.bold())
                        Text(viewModel.sizeLabel)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Tap eye icon to preview • Tap photo to select")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)

                    ForEach(viewModel.assetRows.indices, id: \.self) { section in
                        sectionView(section: section)
                    }
                }
                .padding(.top)
                .padding(.bottom, 100)
            }

            if selectedCount > 0 {
                deleteButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: selectedCount)
        .fullScreenCover(isPresented: $showPreview) {
            if let asset = previewAsset {
                FullScreenPreview(asset: asset, isPresented: $showPreview)
            }
        }
    }

    private func sectionView(section: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.groupType != .other {
                HStack {
                    Text("Group \(section + 1)")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.assetRows[section].count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Select All") {
                        selectAllInSection(section)
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.assetRows[section].indices, id: \.self) { row in
                        let indexPath = IndexPath(row: row, section: section)
                        let isSelected = selectedIndexPaths.contains(indexPath)
                        Option2Cell(
                            asset: viewModel.assetRows[section][row],
                            isSelected: isSelected,
                            isFirst: row == 0 && viewModel.groupType != .other,
                            onSelect: { toggleSelection(indexPath) },
                            onPreview: {
                                previewAsset = viewModel.assetRows[section][row]
                                showPreview = true
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.systemBackground)))
        .padding(.horizontal)
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
        if selectedIndexPaths.contains(indexPath) {
            selectedIndexPaths.remove(indexPath)
        } else {
            selectedIndexPaths.insert(indexPath)
        }
    }

    private func selectAllInSection(_ section: Int) {
        for row in 0..<viewModel.assetRows[section].count {
            if row > 0 || viewModel.groupType == .other {
                selectedIndexPaths.insert(IndexPath(row: row, section: section))
            }
        }
    }
}

struct Option2Cell: View {
    let asset: DBAsset
    let isSelected: Bool
    let isFirst: Bool
    var onSelect: () -> Void
    var onPreview: () -> Void

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 150, height: 150)
            }

            // Top row: Preview button and selection
            VStack {
                HStack {
                    // Preview button
                    Button(action: onPreview) {
                        Image(systemName: "eye.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }

                    Spacer()

                    // Selection checkbox
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .white)
                        .font(.title2)
                        .shadow(radius: 2)
                }
                .padding(8)

                Spacer()

                // Bottom: Best badge
                HStack {
                    if isFirst {
                        Text("Best")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                    Spacer()
                }
                .padding(8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
        .onTapGesture { onSelect() }
        .onAppear { loadImage() }
    }

    private func loadImage() {
        asset.getPHAsset()?.getImage { img in
            DispatchQueue.main.async { self.image = img }
        }
    }
}

// MARK: - Option 3: Preview Button in Section Header
struct PreviewOption3View: View {
    @ObservedObject var viewModelWrapper: BaseViewModelWrapper
    @Binding var selectedIndexPaths: Set<IndexPath>
    @State private var previewSection: Int?
    @State private var showPreview = false
    var onDelete: (() -> Void)?

    private var viewModel: BaseViewModel { viewModelWrapper.viewModel }

    var selectedCount: Int { selectedIndexPaths.count }
    var selectedSize: Int64 {
        selectedIndexPaths.reduce(0) { sum, indexPath in
            guard indexPath.section < viewModel.assetRows.count,
                  indexPath.row < viewModel.assetRows[indexPath.section].count else { return sum }
            return sum + viewModel.assetRows[indexPath.section][indexPath.row].size
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.type.rawValue)
                            .font(.largeTitle.bold())
                        Text(viewModel.sizeLabel)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Tap 'Preview' button in section header")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)

                    ForEach(viewModel.assetRows.indices, id: \.self) { section in
                        sectionView(section: section)
                    }
                }
                .padding(.top)
                .padding(.bottom, 100)
            }

            if selectedCount > 0 {
                deleteButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: selectedCount)
        .fullScreenCover(isPresented: $showPreview) {
            if let section = previewSection, !viewModel.assetRows[section].isEmpty {
                GroupPreviewView(assets: viewModel.assetRows[section], isPresented: $showPreview)
            }
        }
    }

    private func sectionView(section: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(viewModel.groupType != .other ? "Group \(section + 1)" : "Photos")
                    .font(.headline)

                // Preview button
                Button(action: {
                    previewSection = section
                    showPreview = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                        Text("Preview")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.blue.opacity(0.1)))
                }

                Spacer()

                Text("\(viewModel.assetRows[section].count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if viewModel.groupType != .other {
                    Button("Select All") {
                        selectAllInSection(section)
                    }
                    .font(.caption)
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.assetRows[section].indices, id: \.self) { row in
                        let indexPath = IndexPath(row: row, section: section)
                        let isSelected = selectedIndexPaths.contains(indexPath)
                        Option3Cell(
                            asset: viewModel.assetRows[section][row],
                            isSelected: isSelected,
                            isFirst: row == 0 && viewModel.groupType != .other,
                            onTap: { toggleSelection(indexPath) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.systemBackground)))
        .padding(.horizontal)
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
        if selectedIndexPaths.contains(indexPath) {
            selectedIndexPaths.remove(indexPath)
        } else {
            selectedIndexPaths.insert(indexPath)
        }
    }

    private func selectAllInSection(_ section: Int) {
        for row in 0..<viewModel.assetRows[section].count {
            if row > 0 || viewModel.groupType == .other {
                selectedIndexPaths.insert(IndexPath(row: row, section: section))
            }
        }
    }
}

struct Option3Cell: View {
    let asset: DBAsset
    let isSelected: Bool
    let isFirst: Bool
    var onTap: () -> Void

    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .bottom) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 150, height: 150)
            }

            LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                .frame(height: 40)

            HStack {
                if isFirst {
                    Text("Best")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .cornerRadius(4)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
        .onTapGesture { onTap() }
        .onAppear { loadImage() }
    }

    private func loadImage() {
        asset.getPHAsset()?.getImage { img in
            DispatchQueue.main.async { self.image = img }
        }
    }
}

// MARK: - Option 4: Bottom Preview Bar
struct PreviewOption4View: View {
    @ObservedObject var viewModelWrapper: BaseViewModelWrapper
    @Binding var selectedIndexPaths: Set<IndexPath>
    @State private var showPreview = false
    var onDelete: (() -> Void)?

    private var viewModel: BaseViewModel { viewModelWrapper.viewModel }

    var selectedCount: Int { selectedIndexPaths.count }
    var selectedSize: Int64 {
        selectedIndexPaths.reduce(0) { sum, indexPath in
            guard indexPath.section < viewModel.assetRows.count,
                  indexPath.row < viewModel.assetRows[indexPath.section].count else { return sum }
            return sum + viewModel.assetRows[indexPath.section][indexPath.row].size
        }
    }

    var selectedAssets: [DBAsset] {
        selectedIndexPaths.compactMap { indexPath in
            guard indexPath.section < viewModel.assetRows.count,
                  indexPath.row < viewModel.assetRows[indexPath.section].count else { return nil }
            return viewModel.assetRows[indexPath.section][indexPath.row]
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.type.rawValue)
                            .font(.largeTitle.bold())
                        Text(viewModel.sizeLabel)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Tap preview bar at bottom to view selected")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)

                    ForEach(viewModel.assetRows.indices, id: \.self) { section in
                        sectionView(section: section)
                    }
                }
                .padding(.top)
                .padding(.bottom, selectedCount > 0 ? 180 : 100)
            }

            // Bottom bar with preview and delete
            if selectedCount > 0 {
                VStack(spacing: 0) {
                    // Preview thumbnails bar
                    Button(action: { showPreview = true }) {
                        HStack(spacing: -10) {
                            ForEach(Array(selectedAssets.prefix(5).enumerated()), id: \.offset) { index, asset in
                                PreviewThumbnail(asset: asset)
                                    .zIndex(Double(5 - index))
                            }

                            if selectedCount > 5 {
                                Text("+\(selectedCount - 5)")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(Color.blue))
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("Tap to preview")
                                    .font(.caption)
                                Text("\(selectedCount) selected")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)

                    // Delete button
                    deleteButton
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: selectedCount)
        .fullScreenCover(isPresented: $showPreview) {
            if !selectedAssets.isEmpty {
                GroupPreviewView(assets: selectedAssets, isPresented: $showPreview)
            }
        }
    }

    private func sectionView(section: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.groupType != .other {
                HStack {
                    Text("Group \(section + 1)")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.assetRows[section].count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Select All") {
                        selectAllInSection(section)
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.assetRows[section].indices, id: \.self) { row in
                        let indexPath = IndexPath(row: row, section: section)
                        let isSelected = selectedIndexPaths.contains(indexPath)
                        Option3Cell(
                            asset: viewModel.assetRows[section][row],
                            isSelected: isSelected,
                            isFirst: row == 0 && viewModel.groupType != .other,
                            onTap: { toggleSelection(indexPath) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.systemBackground)))
        .padding(.horizontal)
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
        .padding(.vertical, 12)
    }

    private func toggleSelection(_ indexPath: IndexPath) {
        if selectedIndexPaths.contains(indexPath) {
            selectedIndexPaths.remove(indexPath)
        } else {
            selectedIndexPaths.insert(indexPath)
        }
    }

    private func selectAllInSection(_ section: Int) {
        for row in 0..<viewModel.assetRows[section].count {
            if row > 0 || viewModel.groupType == .other {
                selectedIndexPaths.insert(IndexPath(row: row, section: section))
            }
        }
    }
}

struct PreviewThumbnail: View {
    let asset: DBAsset
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
        .onAppear { loadImage() }
    }

    private func loadImage() {
        asset.getPHAsset()?.getImage { img in
            DispatchQueue.main.async { self.image = img }
        }
    }
}

// MARK: - Full Screen Preview
struct FullScreenPreview: View {
    let asset: DBAsset
    @Binding var isPresented: Bool
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
                    .tint(.white)
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onAppear { loadFullImage() }
    }

    private func loadFullImage() {
        asset.getPHAsset()?.getFullImage { img in
            DispatchQueue.main.async { self.image = img }
        }
    }
}

// MARK: - Group Preview View (for Options 3 & 4)
struct GroupPreviewView: View {
    let assets: [DBAsset]
    @Binding var isPresented: Bool
    @State private var currentIndex = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(assets.indices, id: \.self) { index in
                    SingleAssetPreview(asset: assets[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))

            VStack {
                HStack {
                    Text("\(currentIndex + 1) / \(assets.count)")
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.black.opacity(0.5)))

                    Spacer()

                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()

                Spacer()
            }
        }
    }
}

struct SingleAssetPreview: View {
    let asset: DBAsset
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .onAppear { loadImage() }
    }

    private func loadImage() {
        asset.getPHAsset()?.getFullImage { img in
            DispatchQueue.main.async { self.image = img }
        }
    }
}

// MARK: - Preview Options Demo Controller
class PreviewOptionsController: UIViewController {
    private var viewModel: BaseViewModel!
    private var currentOption = 1
    private var hostingController: UIViewController?
    private var selectedIndexPaths: Set<IndexPath> = []
    private var floatingButton: UIButton!

    var predicate: NSPredicate!
    var groupType: PHAssetGroupType = .duplicate
    var type: MediaCellType = .duplicatePhoto

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Option 1"

        viewModel = BaseViewModel(predicate: predicate, groupType: groupType, type: type)
        selectedIndexPaths = viewModel.selectedIndexPath

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showOption(self.currentOption)
            self.setupFloatingButton()
        }
    }

    private func setupFloatingButton() {
        floatingButton = UIButton(type: .system)
        floatingButton.setTitle("Next Option", for: .normal)
        floatingButton.titleLabel?.font = .boldSystemFont(ofSize: 14)
        floatingButton.backgroundColor = .systemBlue
        floatingButton.setTitleColor(.white, for: .normal)
        floatingButton.layer.cornerRadius = 22
        floatingButton.layer.shadowColor = UIColor.black.cgColor
        floatingButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        floatingButton.layer.shadowRadius = 8
        floatingButton.layer.shadowOpacity = 0.3
        floatingButton.translatesAutoresizingMaskIntoConstraints = false
        floatingButton.addTarget(self, action: #selector(switchOption), for: .touchUpInside)
        view.addSubview(floatingButton)
        view.bringSubviewToFront(floatingButton)

        NSLayoutConstraint.activate([
            floatingButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            floatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            floatingButton.widthAnchor.constraint(equalToConstant: 110),
            floatingButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func switchOption() {
        currentOption = (currentOption % 4) + 1
        showOption(currentOption)
        title = "Option \(currentOption)"
    }

    private func showOption(_ option: Int) {
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()

        let wrapper = BaseViewModelWrapper(viewModel: viewModel)
        let binding = Binding<Set<IndexPath>>(
            get: { self.selectedIndexPaths },
            set: { self.selectedIndexPaths = $0 }
        )

        let swiftUIView: AnyView
        switch option {
        case 1:
            swiftUIView = AnyView(PreviewOption1View(
                viewModelWrapper: wrapper,
                selectedIndexPaths: binding,
                onDelete: { [weak self] in self?.handleDelete() }
            ))
        case 2:
            swiftUIView = AnyView(PreviewOption2View(
                viewModelWrapper: wrapper,
                selectedIndexPaths: binding,
                onDelete: { [weak self] in self?.handleDelete() }
            ))
        case 3:
            swiftUIView = AnyView(PreviewOption3View(
                viewModelWrapper: wrapper,
                selectedIndexPaths: binding,
                onDelete: { [weak self] in self?.handleDelete() }
            ))
        case 4:
            swiftUIView = AnyView(PreviewOption4View(
                viewModelWrapper: wrapper,
                selectedIndexPaths: binding,
                onDelete: { [weak self] in self?.handleDelete() }
            ))
        default:
            swiftUIView = AnyView(PreviewOption1View(
                viewModelWrapper: wrapper,
                selectedIndexPaths: binding,
                onDelete: { [weak self] in self?.handleDelete() }
            ))
        }

        let vc = UIHostingController(rootView: swiftUIView)
        addChild(vc)
        vc.view.frame = view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(vc.view, at: 0)
        vc.didMove(toParent: self)
        hostingController = vc

        if floatingButton != nil {
            view.bringSubviewToFront(floatingButton)
        }
    }

    private func handleDelete() {
        let alert = UIAlertController(title: "Delete", message: "Would delete \(selectedIndexPaths.count) items", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
