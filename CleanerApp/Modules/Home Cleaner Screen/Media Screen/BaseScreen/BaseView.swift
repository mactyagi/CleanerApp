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
    @ObservedObject var viewModelWrapper: BaseViewModelWrapper
    @Binding var selectedIndexPaths: Set<IndexPath>
    @State private var previewTarget: PreviewTarget?
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

            if viewModel.assetRows.isEmpty || !viewModel.assetRows.contains(where: { !$0.isEmpty }) {
                MediaEmptyStateView(mediaType: viewModel.type, groupType: viewModel.groupType)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
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
                                        selectedIndexPaths: $selectedIndexPaths,
                                        onPreview: { row in
                                            previewTarget = PreviewTarget(section: section, index: row)
                                        }
                                    )
                                } else {
                                    PhotoSectionView(
                                        assets: viewModel.assetRows[section],
                                        section: section,
                                        groupType: viewModel.groupType,
                                        selectedIndexPaths: $selectedIndexPaths,
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
                                    .fill(Color(UIColor.secondarySystemGroupedBackground))
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
                    selectedIndexPaths: $selectedIndexPaths,
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

        if selectedIndexPaths.contains(indexPath) {
            selectedIndexPaths.remove(indexPath)
        } else {
            selectedIndexPaths.insert(indexPath)
        }
    }

    private func isAllSelectedInSection(_ section: Int) -> Bool {
        let sectionItems = viewModel.assetRows[section]
        for row in 0..<sectionItems.count {
            // Skip first item (best photo) for non-other groups
            if row == 0 && viewModel.groupType != .other { continue }
            let indexPath = IndexPath(row: row, section: section)
            if !selectedIndexPaths.contains(indexPath) {
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
                selectedIndexPaths.remove(IndexPath(row: row, section: section))
            }
        } else {
            // Select all in section (except best photo)
            for row in 0..<viewModel.assetRows[section].count {
                if row > 0 || viewModel.groupType == .other {
                    selectedIndexPaths.insert(IndexPath(row: row, section: section))
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
        let photoCount = assets.count

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
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


// MARK: - Vertical Grid Section View (2 columns, for "other" group)
struct VerticalGridSectionView: View {
    let assets: [DBAsset]
    let section: Int
    @Binding var selectedIndexPaths: Set<IndexPath>
    var onPreview: (Int) -> Void

    private let spacing: CGFloat = 8
    private let horizontalPadding: CGFloat = 16

    private var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let totalPadding = horizontalPadding * 2 + spacing
        return floor((screenWidth - totalPadding) / 2)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(assets.indices, id: \.self) { row in
                let indexPath = IndexPath(row: row, section: section)
                let isSelected = selectedIndexPaths.contains(indexPath)

                BasePhotoCell(
                    asset: assets[row],
                    isSelected: isSelected,
                    isFirst: false,
                    size: cellSize,
                    showSizeLabel: true,
                    onSelect: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if selectedIndexPaths.contains(indexPath) {
                            selectedIndexPaths.remove(indexPath)
                        } else {
                            selectedIndexPaths.insert(indexPath)
                        }
                    },
                    onPreview: { onPreview(row) }
                )
            }
        }
        .padding(.horizontal, horizontalPadding)
    }
}

// MARK: - Photo Cell
struct BasePhotoCell: View {
    let asset: DBAsset
    let isSelected: Bool
    let isFirst: Bool
    var size: CGFloat = 150
    var showSizeLabel: Bool = false
    var onSelect: () -> Void
    var onPreview: () -> Void

    @State private var image: UIImage?
    @State private var isCompressed: Bool = false

    var body: some View {
        ZStack {
            // Background image — tapping anywhere on it selects/deselects
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: size, height: size)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onSelect() }

            VStack {
                // Top row: Best/Compressed badge on left, Preview button on right
                HStack {
                    // Best badge on top left
                    if isFirst {
                        Text("Best")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(4)
                    }

                    Spacer()

                    // Preview button (eye icon) on right
                    Button(action: onPreview) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                }
                .padding(8)

                Spacer()

                // Bottom row: Size label on left, checkbox on right
                HStack {
                    if showSizeLabel {
                        Text(asset.size.convertToFileString())
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                    }

                    Spacer()

                    Button(action: onSelect) {
                        ZStack {
                            Circle()
                                .fill(isSelected ? Color.red : Color.black.opacity(0.4))
                                .frame(width: 30, height: 30)

                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(8)
            }
            .allowsHitTesting(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.red : Color.clear, lineWidth: 3)
        )
        .onAppear { loadImage() }
    }

    private func loadImage() {
        guard let phAsset = asset.getPHAsset() else { return }
        phAsset.getImage { img in
            DispatchQueue.main.async { self.image = img }
        }
        DispatchQueue.global(qos: .utility).async {
            let compressed = asset.isCompressed
            DispatchQueue.main.async { self.isCompressed = compressed }
        }
    }
}

// MARK: - Photo Preview View
struct PhotoPreviewView: View {
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

            // Close button
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

// MARK: - Empty State View
struct MediaEmptyStateView: View {
    let mediaType: MediaCellType
    let groupType: PHAssetGroupType

    @State private var animate = false
    @State private var showConfetti = false

    private var icon: String {
        switch groupType {
        case .duplicate: return "doc.on.doc.fill"
        case .similar: return "photo.on.rectangle.angled"
        default: return "photo.stack.fill"
        }
    }

    private var title: String {
        switch groupType {
        case .duplicate: return "No Duplicates Found"
        case .similar: return "No Similar Items Found"
        default: return "All Clean!"
        }
    }

    private var subtitle: String {
        switch groupType {
        case .duplicate: return "Your library has no duplicate files.\nEverything is unique!"
        case .similar: return "No similar-looking items detected.\nYour collection is well-curated!"
        default: return "Nothing to clean up here.\nYour library is in great shape!"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                // Pulsing background rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(Color.green.opacity(0.08 - Double(index) * 0.02), lineWidth: 2)
                        .frame(
                            width: CGFloat(160 + index * 50),
                            height: CGFloat(160 + index * 50)
                        )
                        .scaleEffect(animate ? 1.05 : 0.95)
                        .animation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                            value: animate
                        )
                }

                // Main icon circle
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.2), Color.green.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 130, height: 130)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                        .shadow(color: Color.green.opacity(0.4), radius: 16, x: 0, y: 8)

                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(animate ? 1.0 : 0.5)
                .opacity(animate ? 1.0 : 0.0)

                // Floating sparkles
                ForEach(0..<6, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: CGFloat.random(in: 10...18)))
                        .foregroundColor(sparkleColor(for: index))
                        .offset(sparkleOffset(for: index))
                        .opacity(showConfetti ? 1 : 0)
                        .scaleEffect(showConfetti ? 1 : 0.3)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.5)
                            .delay(0.4 + Double(index) * 0.08),
                            value: showConfetti
                        )
                }
            }

            Spacer().frame(height: 40)

            // Title
            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 20)

            Spacer().frame(height: 12)

            // Subtitle
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 20)

            Spacer().frame(height: 32)

            // Category pill
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(mediaType.rawValue)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(.green)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.green.opacity(0.1))
            )
            .opacity(animate ? 1 : 0)
            .scaleEffect(animate ? 1 : 0.8)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animate = true
            }
            showConfetti = true
        }
    }

    private func sparkleColor(for index: Int) -> Color {
        let colors: [Color] = [.green, .yellow, .blue, .green, .orange, .mint]
        return colors[index % colors.count]
    }

    private func sparkleOffset(for index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / 6.0) * .pi / 180
        let radius: CGFloat = 85
        return CGSize(
            width: cos(angle) * radius,
            height: sin(angle) * radius
        )
    }
}

// MARK: - ViewModel Wrapper
class BaseViewModelWrapper: ObservableObject {
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

        viewModel.$sizeLabel
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
    }
}
