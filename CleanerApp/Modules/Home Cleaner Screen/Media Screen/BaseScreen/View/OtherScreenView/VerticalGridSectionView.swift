//
//  VerticalGridSectionView.swift
//  CleanerApp
//
//  Created by Manukant Harshmani Tyagi on 23/04/26.
//

import SwiftUI
import Photos

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
