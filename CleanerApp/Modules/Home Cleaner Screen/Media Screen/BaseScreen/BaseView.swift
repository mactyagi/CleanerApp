//
//  BaseView.swift
//  CleanerApp
//
//  SwiftUI implementation for Photo Grid Detail Screen
//

import SwiftUI
import Photos
import Combine

// MARK: - Base View (Production)
struct BaseView: View {
    @ObservedObject var viewModelWrapper: BaseViewModelWrapper
    @Binding var selectedIndexPaths: Set<IndexPath>
    @State private var showPreview = false
    @State private var previewSection: Int = 0
    @State private var previewIndex: Int = 0
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
                    }
                    .padding(.horizontal)

                    // Grouped Sections
                    ForEach(viewModel.assetRows.indices, id: \.self) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            // Section Header
                            if viewModel.groupType != .other {
                                HStack {
                                    Text("\(viewModel.groupType.rawValue.capitalized): \(viewModel.assetRows[section].count)")
                                        .font(.headline)
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
                            }

                            // Photos in section
                            if viewModel.groupType == .other {
                                // Tinder-style swipe cards for "Other" photos
                                SwipeCardPhotoView(
                                    assets: viewModel.assetRows[section],
                                    section: section,
                                    selectedIndexPaths: $selectedIndexPaths,
                                    onPreview: { row in
                                        previewSection = section
                                        previewIndex = row
                                        showPreview = true
                                    }
                                )
                            } else {
                                // Horizontal scroll for grouped photos
                                PhotoSectionView(
                                    assets: viewModel.assetRows[section],
                                    section: section,
                                    groupType: viewModel.groupType,
                                    selectedIndexPaths: $selectedIndexPaths,
                                    onPreview: { row in
                                        previewSection = section
                                        previewIndex = row
                                        showPreview = true
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor.systemBackground))
                        )
                        .padding(.horizontal)
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
            if previewSection < viewModel.assetRows.count {
                ImagePreviewView(
                    assets: viewModel.assetRows[previewSection],
                    initialIndex: previewIndex,
                    selectedIndexPaths: $selectedIndexPaths,
                    section: previewSection,
                    groupType: viewModel.groupType,
                    isPresented: $showPreview
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

// MARK: - Swipe Card View (For "Other" Photos - Tinder Style)
struct SwipeCardPhotoView: View {
    let assets: [DBAsset]
    let section: Int
    @Binding var selectedIndexPaths: Set<IndexPath>
    var onPreview: (Int) -> Void

    @State private var currentIndex: Int = 0
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0

    private var remainingCount: Int {
        assets.count - currentIndex
    }

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
                    // Background cards (show next 2)
                    ForEach(0..<min(3, assets.count - currentIndex), id: \.self) { index in
                        let cardIndex = currentIndex + (2 - index)
                        if cardIndex < assets.count && cardIndex > currentIndex {
                            SwipeCard(
                                asset: assets[cardIndex],
                                onPreview: { onPreview(cardIndex) }
                            )
                            .scaleEffect(1 - CGFloat(2 - index) * 0.05)
                            .offset(y: CGFloat(2 - index) * 8)
                            .allowsHitTesting(false)
                        }
                    }

                    // Top card (interactive)
                    SwipeCard(
                        asset: assets[currentIndex],
                        onPreview: { onPreview(currentIndex) }
                    )
                    .offset(offset)
                    .rotationEffect(.degrees(rotation))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = value.translation
                                rotation = Double(value.translation.width / 20)
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
                    // Delete button (swipe left)
                    Button(action: { swipeLeft() }) {
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

                    // Preview button
                    Button(action: { onPreview(currentIndex) }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 50, height: 50)
                            Image(systemName: "eye.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                    }

                    // Keep button (swipe right)
                    Button(action: { swipeRight() }) {
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

                // Instructions
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
                // All done
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
        }
        .padding(.vertical)
    }

    private var swipeOverlay: some View {
        ZStack {
            // Keep overlay (right swipe)
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

            // Delete overlay (left swipe)
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
            // Reset position
            withAnimation(.spring()) {
                offset = .zero
                rotation = 0
            }
        }
    }

    private func swipeRight() {
        // Keep - don't add to selection
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.easeOut(duration: 0.3)) {
            offset = CGSize(width: 500, height: 0)
            rotation = 15
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentIndex += 1
            offset = .zero
            rotation = 0
        }
    }

    private func swipeLeft() {
        // Delete - add to selection
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        let indexPath = IndexPath(row: currentIndex, section: section)
        selectedIndexPaths.insert(indexPath)

        withAnimation(.easeOut(duration: 0.3)) {
            offset = CGSize(width: -500, height: 0)
            rotation = -15
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentIndex += 1
            offset = .zero
            rotation = 0
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
        // Clear selections for this section
        selectedIndexPaths = selectedIndexPaths.filter { $0.section != section }
    }
}

// MARK: - Swipe Card
struct SwipeCard: View {
    let asset: DBAsset
    var onPreview: () -> Void

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 400)
                ProgressView()
            }

            // Preview button
            VStack {
                HStack {
                    Spacer()
                    Button(action: onPreview) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(12)
                }
                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        .onAppear { loadImage() }
    }

    private func loadImage() {
        asset.getPHAsset()?.getFullImage { img in
            DispatchQueue.main.async { self.image = img }
        }
    }
}

// MARK: - Photo Cell
struct BasePhotoCell: View {
    let asset: DBAsset
    let isSelected: Bool
    let isFirst: Bool
    var size: CGFloat = 150
    var onSelect: () -> Void
    var onPreview: () -> Void

    @State private var image: UIImage?

    var body: some View {
        ZStack {
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

            VStack {
                // Top row: Best badge on left, Preview button on right
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
                            .padding(8)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                }
                .padding(8)

                Spacer()

                // Bottom row: Selection checkbox on right
                HStack {
                    Spacer()

                    // Selection button - red with white checkmark when selected
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
                .padding(8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.red : Color.clear, lineWidth: 3)
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

// MARK: - Hosting Controller
class BaseViewHostingController: UIViewController {
    private var viewModel: BaseViewModel!
    private var hostingController: UIHostingController<AnyView>?
    private var selectedIndexPaths: Set<IndexPath> = []
    private var cancellables = Set<AnyCancellable>()

    var predicate: NSPredicate!
    var groupType: PHAssetGroupType!
    var type: MediaCellType!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        setupViewModel()
        setupSwiftUIView()
        setupNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
    }

    private func setupViewModel() {
        viewModel = BaseViewModel(predicate: predicate, groupType: groupType, type: type)
        selectedIndexPaths = viewModel.selectedIndexPath

        // Observe showLoader for loading state
        viewModel.$showLoader
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showLoader in
                showLoader ? self?.showFullScreenLoader() : self?.hideFullScreenLoader()
            }
            .store(in: &cancellables)

        // Sync selectedIndexPath changes back to viewModel
        viewModel.$selectedIndexPath
            .receive(on: DispatchQueue.main)
            .sink { [weak self] indexPaths in
                self?.selectedIndexPaths = indexPaths
                self?.updateSwiftUIView()
            }
            .store(in: &cancellables)
    }

    private func setupSwiftUIView() {
        let wrapper = BaseViewModelWrapper(viewModel: viewModel)

        let binding = Binding<Set<IndexPath>>(
            get: { self.selectedIndexPaths },
            set: { newValue in
                self.selectedIndexPaths = newValue
                self.viewModel.selectedIndexPath = newValue
                self.viewModel.checkForSelection()
            }
        )

        let swiftUIView = BaseView(
            viewModelWrapper: wrapper,
            selectedIndexPaths: binding,
            onDelete: { [weak self] in
                self?.handleDelete()
            }
        )

        let vc = UIHostingController(rootView: AnyView(swiftUIView))
        addChild(vc)
        vc.view.frame = view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(vc.view)
        vc.didMove(toParent: self)
        hostingController = vc
    }

    private func updateSwiftUIView() {
        // The binding automatically updates the view
    }

    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never

        let selectButton = UIBarButtonItem(
            title: viewModel.isAllSelected ? "Deselect All" : "Select All",
            style: .plain,
            target: self,
            action: #selector(selectionButtonPressed)
        )
        navigationItem.rightBarButtonItem = selectButton

        viewModel.$isAllSelected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAllSelected in
                self?.navigationItem.rightBarButtonItem?.title = isAllSelected ? "Deselect All" : "Select All"
            }
            .store(in: &cancellables)
    }

    @objc private func selectionButtonPressed() {
        viewModel.isAllSelected.toggle()
        if viewModel.isAllSelected {
            viewModel.selectAll()
        } else {
            viewModel.deselectAll()
        }
    }

    private func handleDelete() {
        viewModel.deleteAllSelected()
    }

    // MARK: - Static initializer (matches UIKit version)
    class func customInit(predicate: NSPredicate?, groupType: PHAssetGroupType, type: MediaCellType) -> BaseViewHostingController {
        let vc = BaseViewHostingController()
        vc.predicate = predicate
        vc.groupType = groupType
        vc.type = type
        return vc
    }
}
