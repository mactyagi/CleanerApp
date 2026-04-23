//
//  MediaScreenDesigns.swift
//  CleanerApp
//
//  SwiftUI Media Screen View
//

import SwiftUI
import Photos

// MARK: - Media Screen View (Production)
struct MediaScreenView: View {
    let dataSource: [(title: String, cells: [MediaCell])]
    let totalFiles: Int
    let totalSize: Int64
    var onCellTapped: ((MediaCell) -> Void)?
    var onBackTapped: (() -> Void)?

    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Stats Header
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("Total Storage")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(totalSize.convertToFileString())
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.blue)
                    }

                    Text("\(totalFiles) files to review")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.15), Color(UIColor.systemGroupedBackground)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Category Cards (Design 5 style)
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(dataSource.indices, id: \.self) { sectionIndex in
                            let section = dataSource[sectionIndex]
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: sectionIcon(for: section.title))
                                        .foregroundColor(.blue)
                                    Text(section.title)
                                        .font(.title3.bold())
                                }
                                .padding(.horizontal)

                                ForEach(section.cells.indices, id: \.self) { cellIndex in
                                    let cell = section.cells[cellIndex]
                                    MediaCategoryCard(cell: cell, sectionTotal: sectionTotal(section))
                                        .onTapGesture {
                                            onCellTapped?(cell)
                                        }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    func sectionIcon(for title: String) -> String {
        switch title {
        case "Photos": return "photo.fill"
        case "Screenshots": return "camera.viewfinder"
        case "Videos": return "video.fill"
        default: return "photo"
        }
    }

    func sectionTotal(_ section: (title: String, cells: [MediaCell])) -> Int64 {
        section.cells.reduce(0) { $0 + $1.size }
    }
}

// MARK: - Media Category Card (Design 5 style)
struct MediaCategoryCard: View {
    let cell: MediaCell
    let sectionTotal: Int64

    var progress: CGFloat {
        guard sectionTotal > 0 else { return 0 }
        return CGFloat(cell.size) / CGFloat(sectionTotal)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Stacked thumbnails
            ZStack {
                ForEach(0..<min(cell.asset.count, 3), id: \.self) { index in
                    Image(uiImage: cell.asset[index].getImage() ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .offset(x: CGFloat(index * 6), y: CGFloat(index * -3))
                        .shadow(radius: 2)
                }

                if  cell.asset.isEmpty {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: cell.imageName)
                                .foregroundColor(.blue)
                        )
                }
            }
            .frame(width: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(cell.mainTitle)
                    .font(.headline)

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue.opacity(0.2))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)

                Text("\(cell.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(cell.size.convertToFileString())
                .font(.subheadline.bold())
                .foregroundColor(.blue)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("offWhiteAndGrayColor"))
        )
    }
}
