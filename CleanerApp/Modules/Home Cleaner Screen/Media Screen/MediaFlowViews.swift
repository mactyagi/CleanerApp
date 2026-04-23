//
//  MediaFlowViews.swift
//  CleanerApp
//
//  Pure SwiftUI views for Media navigation flow
//

import SwiftUI
import Photos
import Combine

// MARK: - Media Flow View (Pure SwiftUI)
struct MediaFlowView: View {
    @ObservedObject var viewModel: MediaViewModel
    @Binding var path: NavigationPath
    
    var body: some View {
        MediaScreenView(
            dataSource: viewModel.dataSource,
            totalFiles: viewModel.totalFiles,
            totalSize: viewModel.totalSize,
            onCellTapped: { cell in
                if cell.cellType.groupType == .other {
                    path.append(MediaDestination.otherPhotos(cell.cellType))
                } else {
                    path.append(MediaDestination.baseView(cell.cellType))
                }
            },
            onBackTapped: {
                if !path.isEmpty {
                    path.removeLast()
                }
            }
        )
        .navigationTitle("Media Cleaner")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchAllMediaType()
        }
    }
}

// MARK: - Media Navigation Destinations
enum MediaDestination: Hashable {
    case baseView(MediaCellType)
    case otherPhotos(MediaCellType)
}



