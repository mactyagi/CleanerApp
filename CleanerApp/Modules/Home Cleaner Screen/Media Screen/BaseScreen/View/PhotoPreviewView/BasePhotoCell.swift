//
//  BasePhotoCell.swift
//  CleanerApp
//
//  Created by Manukant Harshmani Tyagi on 23/04/26.
//

import SwiftUI
import Photos

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
        
        .task {
            await loadImage()
        }
    }

    
    private func loadImage() async {
        guard let phAsset = asset.getPHAsset() else { return }
            image = await phAsset.getImage()
    }
}
