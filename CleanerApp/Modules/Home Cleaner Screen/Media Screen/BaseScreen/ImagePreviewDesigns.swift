//
//  ImagePreviewDesigns.swift
//  CleanerApp
//
//  Image Preview View for Media Screen
//

import SwiftUI
import UIKit
import Photos

// MARK: - Image Preview View (Production)
struct ImagePreviewView: View {
    let assets: [DBAsset]
    let initialIndex: Int
    @Binding var selectedIndexPaths: Set<IndexPath>
    let section: Int
    let groupType: PHAssetGroupType
    @Binding var isPresented: Bool

    @State private var currentIndex: Int
    @State private var sheetExpanded = false

    init(assets: [DBAsset], initialIndex: Int, selectedIndexPaths: Binding<Set<IndexPath>>, section: Int, groupType: PHAssetGroupType, isPresented: Binding<Bool>) {
        self.assets = assets
        self.initialIndex = initialIndex
        self._selectedIndexPaths = selectedIndexPaths
        self.section = section
        self.groupType = groupType
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            // Main image pager
            TabView(selection: $currentIndex) {
                ForEach(assets.indices, id: \.self) { index in
                    FullImageView(asset: assets[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            // Top bar (Design 1 style)
            VStack {
                HStack {
                    // Close button
                    Button(action: { isPresented = false }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    // Counter pill
                    Text("\(currentIndex + 1) of \(assets.count)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.2)))

                    Spacer()

                    // Select button
                    Button(action: { toggleSelection(currentIndex) }) {
                        Image(systemName: isSelected(currentIndex) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(isSelected(currentIndex) ? .red : .white)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .background(LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom))

                Spacer()
            }

            // Bottom sheet (Design 5 style)
            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .onTapGesture {
                        withAnimation(.spring()) { sheetExpanded.toggle() }
                    }

                // Best badge and select row
                HStack {
                    if currentIndex == 0 && groupType != .other {
                        Text("BEST")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green)
                            .cornerRadius(4)
                    }

                    Spacer()

                    Button(action: { toggleSelection(currentIndex) }) {
                        HStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(isSelected(currentIndex) ? Color.red : Color.clear)
                                    .frame(width: 24, height: 24)
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                if isSelected(currentIndex) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            Text(isSelected(currentIndex) ? "Selected" : "Select")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // Thumbnail grid (expanded) or horizontal scroll (compact)
                if sheetExpanded {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 4) {
                        ForEach(assets.indices, id: \.self) { index in
                            ZStack(alignment: .topLeading) {
                                SmallThumbnail(asset: assets[index], size: 80)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(currentIndex == index ? Color.white : Color.clear, lineWidth: 2)
                                    )

                                if index == 0 && groupType != .other {
                                    Text("Best")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.green)
                                        .cornerRadius(3)
                                        .offset(x: 4, y: 4)
                                }

                                if isSelected(index) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                        .offset(x: -4, y: 4)
                                }
                            }
                            .onTapGesture { withAnimation { currentIndex = index } }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom))
                } else {
                    // Compact horizontal thumbnails
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(assets.indices, id: \.self) { index in
                                    ZStack(alignment: .topLeading) {
                                        SmallThumbnail(asset: assets[index], size: 56)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(currentIndex == index ? Color.white : Color.clear, lineWidth: 2)
                                            )

                                        if index == 0 && groupType != .other {
                                            Text("Best")
                                                .font(.system(size: 7, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 3)
                                                .padding(.vertical, 1)
                                                .background(Color.green)
                                                .cornerRadius(2)
                                                .offset(x: 2, y: 2)
                                        }

                                        if isSelected(index) {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 16, height: 16)
                                                .overlay(
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 8, weight: .bold))
                                                        .foregroundColor(.white)
                                                )
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                                .offset(x: -2, y: 2)
                                        }
                                    }
                                    .id(index)
                                    .onTapGesture { withAnimation { currentIndex = index } }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .onChange(of: currentIndex) { newValue in
                            withAnimation { proxy.scrollTo(newValue, anchor: .center) }
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.15))
            )
        }
    }

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
                Rectangle().fill(Color.gray.opacity(0.3))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onAppear { loadImage() }
    }

    private func loadImage() {
        asset.getPHAsset()?.getImage { img in
            DispatchQueue.main.async { self.image = img }
        }
    }
}

struct FullImageView: View {
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
