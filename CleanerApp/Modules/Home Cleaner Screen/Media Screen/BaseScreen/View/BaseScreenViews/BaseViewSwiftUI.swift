//
//  BaseViewSwiftUI.swift
//  CleanerApp
//
//  Created by Manukant Harshmani Tyagi on 23/04/26.
//

import SwiftUI
import Photos

struct BaseViewSwiftUI: View {
    let predicate: NSPredicate
    let groupType: PHAssetGroupType
    let type: MediaCellType
    
//    @StateObject private var viewModelWrapper: BaseViewModelWrapperSwiftUI
    @StateObject private var baseViewModel: BaseViewModel
//    @State private var selectedIndexPaths: Set<IndexPath> = []
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    init(predicate: NSPredicate, groupType: PHAssetGroupType, type: MediaCellType) {
        self.predicate = predicate
        self.groupType = groupType
        self.type = type
        
        _baseViewModel = StateObject(wrappedValue: BaseViewModel(predicate: predicate, groupType: groupType, type: type))
    }
    
    var body: some View {
        BaseView(
            viewModel: baseViewModel,
//            selectedIndexPaths: $selectedIndexPaths,
            onDelete: {
                showDeleteAlert = true
            }
        )
        .navigationTitle(type.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !baseViewModel.assetRows.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        baseViewModel.isAllSelected.toggle()
                        if baseViewModel.isAllSelected {
                            baseViewModel.selectAll()
                        } else {
                            baseViewModel.deselectAll()
                        }
//                        selectedIndexPaths = baseViewModel.selectedIndexPath
                    }) {
                        Text(baseViewModel.isAllSelected ? "Deselect All" : "Select All")
                            .font(.system(size: 15, weight: .medium))
                    }
                }
            }
        }
        .alert("Delete Photos", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                baseViewModel.deleteAllSelected()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(baseViewModel.selectedIndexPath.count) items?")
        }
        .overlay {
            if baseViewModel.showLoader {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
    }
}
