//
//  ImagePreviewDesigns.swift
//  CleanerApp
//
//  Image Preview View for Media Screen
//

import SwiftUI
import Photos
import AVKit

// MARK: - Image Preview View (Production)
struct ImagePreviewView: View {
    let assets: [DBAsset]
    let initialIndex: Int
    @Binding var selectedIndexPaths: Set<IndexPath>
    let section: Int
    let groupType: PHAssetGroupType
    @Binding var isPresented: Bool

    @State private var currentIndex: Int
    @State private var dragOffset: CGFloat = 0
    @State private var isCurrentCompressed = false

    init(assets: [DBAsset], initialIndex: Int, selectedIndexPaths: Binding<Set<IndexPath>>, section: Int, groupType: PHAssetGroupType, isPresented: Binding<Bool>) {
        self.assets = assets
        self.initialIndex = initialIndex
        self._selectedIndexPaths = selectedIndexPaths
        self.section = section
        self.groupType = groupType
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: initialIndex)
    }

    private var isBestPhoto: Bool {
        currentIndex == 0 && groupType != .other
    }

    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Navigation Bar
                topBar
                    .padding(.top, 8)

                // Best Result / Photo info badge
                photoBadge
                    .padding(.top, 4)
                    .padding(.bottom, 12)

                // Main Photo
                mainPhotoSection

                Spacer(minLength: 12)

                // Selection button
                selectionButton
                    .padding(.bottom, 12)

                // Bottom Thumbnail Strip
                thumbnailStrip
                    .padding(.bottom, 8)
                    .frame(height: 88)
            }
        }
        .statusBarHidden(false)
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Back button
            Button(action: { isPresented = false }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(UIColor.label))
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    )
            }

            Spacer()

            // Counter pill
            Text("\(currentIndex + 1) / \(assets.count)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(UIColor.secondarySystemBackground))
                )

            Spacer()

            // Spacer for symmetry
            Color.clear
                .frame(width: 42, height: 42)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Photo Badge
    private var photoBadge: some View {
        HStack(alignment: .center) {
            if isBestPhoto {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)

                    Text("Best Result")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                }
            } else if isSelected(currentIndex) {
                HStack(spacing: 8) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .frame(width: 24, height: 24)

                    Text("Marked for Deletion")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                }
            } else {
                HStack(spacing: 8) {
                    let isVideoAsset = assets[currentIndex].getPHAsset()?.mediaType == .video
                    Image(systemName: isVideoAsset ? "video" : "photo")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)

                    Text(isVideoAsset ? "Video \(currentIndex + 1)" : "Photo \(currentIndex + 1)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Compressed tag — top right, aligned with badge
            if isCurrentCompressed {
                Text("Compressed")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.green))
            }
        }
        .frame(height: 28)
        .padding(.horizontal, 24)
        .onChange(of: currentIndex) { _ in checkCompressed() }
        .onAppear { checkCompressed() }
    }

    private func checkCompressed() {
        DispatchQueue.global(qos: .utility).async {
            let compressed = assets[currentIndex].isCompressed
            DispatchQueue.main.async { isCurrentCompressed = compressed }
        }
    }

    // MARK: - Main Photo
    private var mainPhotoSection: some View {
        TabView(selection: $currentIndex) {
            ForEach(assets.indices, id: \.self) { index in
                FullImageView(asset: assets[index], isActive: currentIndex == index)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 4)
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }

    // MARK: - Selection Row (size left, ring center-right, compressed right)
    private var selectionButton: some View {
        HStack {
            // File size — left most
            Text(assets[currentIndex].size.convertToFileString())
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.blue))

            Spacer()

            // Selection ring
            Button(action: { toggleSelection(currentIndex) }) {
                ZStack {
                    if isSelected(currentIndex) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 36, height: 36)
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color(UIColor.tertiaryLabel), lineWidth: 2.5)
                            .frame(width: 36, height: 36)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Thumbnail Strip
    private var thumbnailStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(assets.indices, id: \.self) { index in
                        thumbnailItem(index: index)
                            .id(index)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    currentIndex = index
                                }
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
//            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.offWhiteAndGray)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: -2)
            )
            .onChange(of: currentIndex) { newValue in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    private func thumbnailItem(index: Int) -> some View {
        let isCurrentlyViewed = currentIndex == index
        let isThumbnailSelected = isSelected(index)
        let isBest = index == 0 && groupType != .other

        return ZStack(alignment: .bottomTrailing) {
            SmallThumbnail(asset: assets[index], size: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isCurrentlyViewed ? Color.blue : Color.clear,
                            lineWidth: 3
                        )
                )
                .shadow(color: isCurrentlyViewed ? Color.blue.opacity(0.3) : .clear, radius: 6, x: 0, y: 2)

            // Best badge overlay
            if isBest {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                    )
                    .offset(x: 4, y: 4)
            }

            // Selection indicator
            if isThumbnailSelected {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 4, y: 4)
            }
        }
    }

    // MARK: - Helpers
    private func isSelected(_ index: Int) -> Bool {
        selectedIndexPaths.contains(IndexPath(row: index, section: section))
    }

    private func toggleSelection(_ index: Int) {
        let indexPath = IndexPath(row: index, section: section)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        if selectedIndexPaths.contains(indexPath) {
            selectedIndexPaths.remove(indexPath)
        } else {
            selectedIndexPaths.insert(indexPath)
        }
    }
}

// MARK: - Helper Views

struct SmallThumbnail: View {
    let asset: DBAsset
    let size: CGFloat
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle().fill(Color.gray.opacity(0.15))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .task {
            await loadImage()
        }
    }

    private func loadImage() async  {
        image =  await asset.getPHAsset()?.getImage()
    }
}

struct FullImageView: View {
    let asset: DBAsset
    var isActive: Bool = true
    @State private var image: UIImage?
    @State private var avAsset: AVAsset?
    @State private var isVideo = false

    var body: some View {
        // Color.clear fills the full page so layout never shifts when content loads
        Color.offWhiteAndGray
            .overlay(contentView)
            .task {
                await loadContent()
            }
    }

    @ViewBuilder
    private var contentView: some View {
        if isVideo {
            if let avAsset = avAsset {
                PreviewVideoPlayerView(avAsset: avAsset, isActive: isActive)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ZStack {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    ProgressView()
                        .tint(.secondary)
                }
            }
        } else {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ProgressView()
                    .tint(.secondary)
            }
        }
    }

    private func loadContent() async {
        guard let phAsset = asset.getPHAsset() else { return }

        if phAsset.mediaType == .video {
            DispatchQueue.main.async { self.isVideo = true }
            image = await phAsset.getImage()
    
            avAsset = await phAsset.getAVAsset()
           
        } else {
            image = await phAsset.getFullImage()
        }
    }
}

// MARK: - Native AVPlayerViewController wrapper
struct PreviewVideoPlayerView: UIViewControllerRepresentable {
    let avAsset: AVAsset
    let isActive: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        weak var player: AVPlayer?
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(playerItem: AVPlayerItem(asset: avAsset))
        controller.player = player
        controller.videoGravity = .resizeAspect
        controller.view.backgroundColor = .clear
        context.coordinator.player = player
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if !isActive {
            uiViewController.player?.pause()
        }
    }

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        uiViewController.player?.pause()
        uiViewController.player = nil
    }
}

// MARK: - Preview
#Preview("Image Preview") {
    ImagePreviewView(
        assets: [],
        initialIndex: 0,
        selectedIndexPaths: .constant([]),
        section: 0,
        groupType: .other,
        isPresented: .constant(true)
    )
}


