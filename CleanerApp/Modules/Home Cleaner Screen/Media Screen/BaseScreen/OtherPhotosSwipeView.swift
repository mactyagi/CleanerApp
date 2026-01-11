//
//  OtherPhotosSwipeView.swift
//  CleanerApp
//
//  Other Photos Overview and Swipe Views
//

import SwiftUI
import UIKit
import Photos

// MARK: - Other Photos Overview Screen
struct OtherPhotosOverviewScreen: View {
    let assets: [DBAsset]
    @Binding var selectedIndexPaths: Set<IndexPath>
    @Binding var isPresented: Bool
    let section: Int

    @State private var showSwipeView = false

    private var totalSize: Int64 {
        assets.reduce(0) { $0 + $1.size }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button(action: { isPresented = false }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.blue)
                        }

                        Spacer()
                    }

                    Text("Other Photos")
                        .font(.system(size: 34, weight: .bold))

                    HStack(spacing: 16) {
                        Label("\(assets.count) photos", systemImage: "photo")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Label(totalSize.convertToFileString(), systemImage: "internaldrive")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))

                // Photo Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(assets.indices, id: \.self) { index in
                            PhotoGridCell(asset: assets[index])
                        }
                    }
                    .padding(.horizontal, 8)
                }

                // Bottom Action Bar
                VStack(spacing: 12) {
                    // Start Review Button
                    Button(action: { showSwipeView = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "hand.draw")
                                .font(.system(size: 20))
                            Text("Start Swipe Review")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.blue)
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
                .background(
                    Color(UIColor.systemBackground)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                )
            }
        }
        .fullScreenCover(isPresented: $showSwipeView) {
            OtherPhotosSwipeView(
                assets: assets,
                selectedIndexPaths: $selectedIndexPaths,
                isPresented: $showSwipeView,
                section: section
            )
        }
    }
}

// MARK: - Photo Grid Cell
struct PhotoGridCell: View {
    let asset: DBAsset

    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.width)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    ProgressView()
                }

                // Size label at bottom
                VStack {
                    Spacer()
                    HStack {
                        Text(asset.size.convertToFileString())
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.65))
                            )
                        Spacer()
                    }
                    .padding(8)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.width)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear { loadImage() }
    }

    private func loadImage() {
        asset.getPHAsset()?.getImage { img in
            DispatchQueue.main.async { self.image = img }
        }
    }
}

// MARK: - Other Photos Swipe View
struct OtherPhotosSwipeView: View {
    let assets: [DBAsset]
    @Binding var selectedIndexPaths: Set<IndexPath>
    @Binding var isPresented: Bool
    let section: Int

    @State private var currentIndex: Int = 0
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                // Header
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("\(currentIndex + 1) / \(assets.count)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("\(deletedCount) to delete")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }

                    Spacer()

                    // Undo button
                    Button(action: undoLast) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(currentIndex > 0 ? .white : .gray)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(currentIndex == 0)
                }
                .padding(.horizontal)

                if currentIndex < assets.count {
                    // Card with swipe overlay
                    ZStack {
                        SwipeCardView(asset: assets[currentIndex])
                            .frame(height: 480)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                        // Swipe overlay - shows when swiping
                        swipeOverlay
                    }
                    .padding(.horizontal, 16)
                    .offset(offset)
                    .rotationEffect(.degrees(Double(offset.width / 25)))
                    .gesture(
                        DragGesture()
                            .onChanged { offset = $0.translation }
                            .onEnded { handleSwipe($0) }
                    )

                    Spacer()

                    // Action buttons with text
                    HStack(spacing: 50) {
                        // Delete button
                        Button(action: swipeLeft) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.red, lineWidth: 3)
                                        .frame(width: 70, height: 70)
                                    Text("Delete")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        // Keep button
                        Button(action: swipeRight) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.green, lineWidth: 3)
                                        .frame(width: 70, height: 70)
                                    Text("Keep")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 40)
                } else {
                    CompletionView(deletedCount: deletedCount, onReset: resetCards, onDone: { isPresented = false }, darkMode: true)
                }
            }
        }
    }

    // Swipe overlay that shows on top of photo
    private var swipeOverlay: some View {
        ZStack {
            // Keep overlay (right swipe)
            if offset.width > 30 {
                VStack {
                    Text("KEEP")
                        .font(.system(size: 42, weight: .black))
                        .foregroundColor(.green)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green, lineWidth: 4)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.2)))
                        )
                        .rotationEffect(.degrees(-20))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.green.opacity(Double(offset.width - 30) / 300 * 0.3))
                .opacity(min(Double(offset.width - 30) / 80, 1))
            }

            // Delete overlay (left swipe)
            if offset.width < -30 {
                VStack {
                    Text("DELETE")
                        .font(.system(size: 42, weight: .black))
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red, lineWidth: 4)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.2)))
                        )
                        .rotationEffect(.degrees(20))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.red.opacity(Double(-offset.width - 30) / 300 * 0.3))
                .opacity(min(Double(-offset.width - 30) / 80, 1))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var deletedCount: Int {
        selectedIndexPaths.filter { $0.section == section }.count
    }

    private func handleSwipe(_ value: DragGesture.Value) {
        if value.translation.width > 100 { swipeRight() }
        else if value.translation.width < -100 { swipeLeft() }
        else { withAnimation(.spring()) { offset = .zero } }
    }

    private func swipeRight() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.easeOut(duration: 0.25)) { offset = CGSize(width: 500, height: 0) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentIndex += 1
            offset = .zero
        }
    }

    private func swipeLeft() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        selectedIndexPaths.insert(IndexPath(row: currentIndex, section: section))
        withAnimation(.easeOut(duration: 0.25)) { offset = CGSize(width: -500, height: 0) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentIndex += 1
            offset = .zero
        }
    }

    private func undoLast() {
        guard currentIndex > 0 else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        currentIndex -= 1
        selectedIndexPaths.remove(IndexPath(row: currentIndex, section: section))
    }

    private func resetCards() {
        currentIndex = 0
        selectedIndexPaths = selectedIndexPaths.filter { $0.section != section }
    }
}

// MARK: - Helper Views

struct SwipeCardView: View {
    let asset: DBAsset
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle().fill(Color.gray.opacity(0.2))
                ProgressView()
            }
        }
        .clipped()
        .onAppear { loadImage() }
    }

    private func loadImage() {
        asset.getPHAsset()?.getFullImage { img in
            DispatchQueue.main.async { self.image = img }
        }
    }
}

struct CompletionView: View {
    let deletedCount: Int
    let onReset: () -> Void
    let onDone: () -> Void
    var darkMode: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.green)

            Text("All Done!")
                .font(.title.bold())
                .foregroundColor(darkMode ? .white : .primary)

            Text("\(deletedCount) photos marked for deletion")
                .font(.subheadline)
                .foregroundColor(darkMode ? .gray : .secondary)

            HStack(spacing: 16) {
                Button(action: onReset) {
                    Text("Review Again")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Capsule().stroke(Color.blue, lineWidth: 1))
                }

                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.blue))
                }
            }
            .padding(.top)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Hosting Controller
class OtherPhotosSwipeHostingController: UIViewController {
    var assets: [DBAsset] = []
    var selectedIndexPaths: Set<IndexPath> = []
    var section: Int = 0
    var onDismiss: ((Set<IndexPath>) -> Void)?

    private var hostingController: UIHostingController<AnyView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwiftUIView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupSwiftUIView() {
        let isPresentedBinding = Binding<Bool>(
            get: { true },
            set: { [weak self] value in
                if !value {
                    self?.onDismiss?(self?.selectedIndexPaths ?? [])
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        )

        let selectedBinding = Binding<Set<IndexPath>>(
            get: { self.selectedIndexPaths },
            set: { self.selectedIndexPaths = $0 }
        )

        let swiftUIView = OtherPhotosOverviewScreen(
            assets: assets,
            selectedIndexPaths: selectedBinding,
            isPresented: isPresentedBinding,
            section: section
        )

        let vc = UIHostingController(rootView: AnyView(swiftUIView))
        addChild(vc)
        vc.view.frame = view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(vc.view)
        vc.didMove(toParent: self)
        hostingController = vc
    }

    static func create(assets: [DBAsset], section: Int, selectedIndexPaths: Set<IndexPath>, onDismiss: @escaping (Set<IndexPath>) -> Void) -> OtherPhotosSwipeHostingController {
        let vc = OtherPhotosSwipeHostingController()
        vc.assets = assets
        vc.section = section
        vc.selectedIndexPaths = selectedIndexPaths
        vc.onDismiss = onDismiss
        return vc
    }
}
