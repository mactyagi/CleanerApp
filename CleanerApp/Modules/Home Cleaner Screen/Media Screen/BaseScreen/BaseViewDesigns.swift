//
//  BaseViewDesigns.swift
//  CleanerApp
//
//  SwiftUI Design Options for Photo Grid Detail Screen (BaseViewController)
//

import SwiftUI
import UIKit
import Photos

// MARK: - Design 1: Clean Grid with Floating Delete
struct BaseViewDesign1: View {
    let title: String
    let subtitle: String
    let assetRows: [[DBAsset]]
    let groupType: PHAssetGroupType
    @Binding var selectedIndexPaths: Set<IndexPath>
    var onDelete: (() -> Void)?

    var selectedCount: Int { selectedIndexPaths.count }
    var selectedSize: Int64 {
        selectedIndexPaths.reduce(0) { sum, indexPath in
            guard indexPath.section < assetRows.count,
                  indexPath.row < assetRows[indexPath.section].count else { return sum }
            return sum + assetRows[indexPath.section][indexPath.row].size
        }
    }

    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.largeTitle.bold())
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Photo Grid
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(assetRows.indices, id: \.self) { section in
                            ForEach(assetRows[section].indices, id: \.self) { row in
                                let indexPath = IndexPath(row: row, section: section)
                                let isSelected = selectedIndexPaths.contains(indexPath)
                                PhotoCell1(
                                    asset: assetRows[section][row],
                                    isSelected: isSelected,
                                    isFirst: row == 0 && groupType != .other
                                ) {
                                    toggleSelection(indexPath)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
                .padding(.top)
            }

            // Floating Delete Button
            if selectedCount > 0 {
                deleteButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: selectedCount)
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
        if selectedIndexPaths.contains(indexPath) {
            selectedIndexPaths.remove(indexPath)
        } else {
            selectedIndexPaths.insert(indexPath)
        }
    }
}

struct PhotoCell1: View {
    let asset: DBAsset
    let isSelected: Bool
    let isFirst: Bool
    var onTap: () -> Void

    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Photo
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(1, contentMode: .fill)
            }

            // Selection indicator
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : Color.white.opacity(0.8))
                    .frame(width: 24, height: 24)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
            }
            .padding(6)

            // "Keep" badge for first item
            if isFirst {
                VStack {
                    Spacer()
                    Text("KEEP")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(4)
                        .padding(6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
        .onTapGesture { onTap() }
        .onAppear { loadImage() }
    }

    private func loadImage() {
        asset.getPHAsset()?.getImage { img in
            DispatchQueue.main.async { self.image = img }
        }
    }
}

// MARK: - Design 2: Grouped Sections with Headers
struct BaseViewDesign2: View {
    let title: String
    let subtitle: String
    let assetRows: [[DBAsset]]
    let groupType: PHAssetGroupType
    @Binding var selectedIndexPaths: Set<IndexPath>
    var onDelete: (() -> Void)?

    var selectedCount: Int { selectedIndexPaths.count }
    var selectedSize: Int64 {
        selectedIndexPaths.reduce(0) { sum, indexPath in
            guard indexPath.section < assetRows.count,
                  indexPath.row < assetRows[indexPath.section].count else { return sum }
            return sum + assetRows[indexPath.section][indexPath.row].size
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header (Design 1 style)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.largeTitle.bold())
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Grouped Sections
                    ForEach(assetRows.indices, id: \.self) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            // Section Header
                            if groupType != .other {
                                HStack {
                                    Text("Group \(section + 1)")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(assetRows[section].count) items")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Button("Select All") {
                                        selectAllInSection(section)
                                    }
                                    .font(.caption)
                                }
                                .padding(.horizontal)
                            }

                            // Photos in section
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(assetRows[section].indices, id: \.self) { row in
                                        let indexPath = IndexPath(row: row, section: section)
                                        let isSelected = selectedIndexPaths.contains(indexPath)
                                        PhotoCell2(
                                            asset: assetRows[section][row],
                                            isSelected: isSelected,
                                            isFirst: row == 0 && groupType != .other
                                        ) {
                                            toggleSelection(indexPath)
                                        }
                                    }
                                }
                                .padding(.horizontal)
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

            // Floating Delete Button (Design 1 style)
            if selectedCount > 0 {
                deleteButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: selectedCount)
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
        if selectedIndexPaths.contains(indexPath) {
            selectedIndexPaths.remove(indexPath)
        } else {
            selectedIndexPaths.insert(indexPath)
        }
    }

    private func selectAllInSection(_ section: Int) {
        for row in 0..<assetRows[section].count {
            if row > 0 || groupType == .other {
                selectedIndexPaths.insert(IndexPath(row: row, section: section))
            }
        }
    }
}

struct PhotoCell2: View {
    let asset: DBAsset
    let isSelected: Bool
    let isFirst: Bool
    var onTap: () -> Void

    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .bottom) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 120)
            }

            // Bottom gradient
            LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                .frame(height: 40)

            // Labels
            HStack {
                if isFirst {
                    Text("Best")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .cornerRadius(4)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
        .onTapGesture { onTap() }
        .onAppear { loadImage() }
    }

    private func loadImage() {
        asset.getPHAsset()?.getImage { img in
            DispatchQueue.main.async { self.image = img }
        }
    }
}

// MARK: - Design 3: Compact with Quick Actions
struct BaseViewDesign3: View {
    let title: String
    let subtitle: String
    let assetRows: [[DBAsset]]
    let groupType: PHAssetGroupType
    @Binding var selectedIndexPaths: Set<IndexPath>
    var onDelete: (() -> Void)?

    var selectedCount: Int { selectedIndexPaths.count }
    var totalCount: Int { assetRows.reduce(0) { $0 + $1.count } }
    var selectedSize: Int64 {
        selectedIndexPaths.reduce(0) { sum, indexPath in
            guard indexPath.section < assetRows.count,
                  indexPath.row < assetRows[indexPath.section].count else { return sum }
            return sum + assetRows[indexPath.section][indexPath.row].size
        }
    }

    let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar with Quick Actions
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text("\(selectedCount)/\(totalCount) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Select All") { selectAll() }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.blue.opacity(0.1)))

                Button("Clear") { clearSelection() }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.gray.opacity(0.1)))
            }
            .padding()
            .background(Color(UIColor.systemBackground))

            // Compact Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(assetRows.indices, id: \.self) { section in
                        ForEach(assetRows[section].indices, id: \.self) { row in
                            let indexPath = IndexPath(row: row, section: section)
                            let isSelected = selectedIndexPaths.contains(indexPath)
                            PhotoCell3(
                                asset: assetRows[section][row],
                                isSelected: isSelected,
                                isFirst: row == 0 && groupType != .other
                            ) {
                                toggleSelection(indexPath)
                            }
                        }
                    }
                }
                .padding(4)
                .padding(.bottom, 80)
            }
            .background(Color(UIColor.systemGroupedBackground))

            // Bottom Delete Bar
            HStack {
                Image(systemName: "trash")
                    .foregroundColor(selectedCount > 0 ? .red : .gray)
                Text(selectedCount > 0 ? "Delete \(selectedCount) (\(selectedSize.convertToFileString()))" : "Select items to delete")
                    .font(.subheadline)
                Spacer()
                Button(action: { onDelete?() }) {
                    Text("Delete")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(selectedCount > 0 ? Color.red : Color.gray))
                }
                .disabled(selectedCount == 0)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
        }
    }

    private func toggleSelection(_ indexPath: IndexPath) {
        if selectedIndexPaths.contains(indexPath) {
            selectedIndexPaths.remove(indexPath)
        } else {
            selectedIndexPaths.insert(indexPath)
        }
    }

    private func selectAll() {
        for section in assetRows.indices {
            for row in assetRows[section].indices {
                if row > 0 || groupType == .other {
                    selectedIndexPaths.insert(IndexPath(row: row, section: section))
                }
            }
        }
    }

    private func clearSelection() {
        selectedIndexPaths.removeAll()
    }
}

struct PhotoCell3: View {
    let asset: DBAsset
    let isSelected: Bool
    let isFirst: Bool
    var onTap: () -> Void

    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(1, contentMode: .fill)
            }

            // Selection overlay
            if isSelected {
                Color.blue.opacity(0.3)
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .padding(4)
            }

            // Keep badge
            if isFirst {
                HStack {
                    Spacer()
                    Text("K")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color.green))
                        .padding(4)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onTapGesture { onTap() }
        .onAppear { loadImage() }
    }

    private func loadImage() {
        asset.getPHAsset()?.getImage { img in
            DispatchQueue.main.async { self.image = img }
        }
    }
}

// MARK: - Design Preview Controller for BaseView
class BaseViewDesignPreviewController: UIViewController {
    private var viewModel: BaseViewModel!
    private var currentDesign = 1
    private var hostingController: UIViewController?
    private var floatingButton: UIButton!
    private var selectedIndexPaths: Set<IndexPath> = []

    var predicate: NSPredicate!
    var groupType: PHAssetGroupType = .duplicate
    var type: MediaCellType = .duplicatePhoto

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Design 1"

        viewModel = BaseViewModel(predicate: predicate, groupType: groupType, type: type)
        selectedIndexPaths = viewModel.selectedIndexPath

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showDesign(self.currentDesign)
            self.setupFloatingButton()
        }
    }

    private func setupFloatingButton() {
        floatingButton = UIButton(type: .system)
        floatingButton.setTitle("Next Design", for: .normal)
        floatingButton.titleLabel?.font = .boldSystemFont(ofSize: 14)
        floatingButton.backgroundColor = .systemBlue
        floatingButton.setTitleColor(.white, for: .normal)
        floatingButton.layer.cornerRadius = 25
        floatingButton.layer.shadowColor = UIColor.black.cgColor
        floatingButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        floatingButton.layer.shadowRadius = 8
        floatingButton.layer.shadowOpacity = 0.3
        floatingButton.translatesAutoresizingMaskIntoConstraints = false
        floatingButton.addTarget(self, action: #selector(switchDesign), for: .touchUpInside)
        view.addSubview(floatingButton)
        view.bringSubviewToFront(floatingButton)

        NSLayoutConstraint.activate([
            floatingButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            floatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            floatingButton.widthAnchor.constraint(equalToConstant: 120),
            floatingButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func switchDesign() {
        currentDesign = (currentDesign % 3) + 1
        showDesign(currentDesign)
        title = "Design \(currentDesign)"
    }

    private func showDesign(_ design: Int) {
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()

        let binding = Binding<Set<IndexPath>>(
            get: { self.selectedIndexPaths },
            set: { self.selectedIndexPaths = $0 }
        )

        let swiftUIView: AnyView
        switch design {
        case 1:
            swiftUIView = AnyView(BaseViewDesign1(
                title: type.rawValue,
                subtitle: viewModel.sizeLabel,
                assetRows: viewModel.assetRows,
                groupType: groupType,
                selectedIndexPaths: binding,
                onDelete: { [weak self] in self?.handleDelete() }
            ))
        case 2:
            swiftUIView = AnyView(BaseViewDesign2(
                title: type.rawValue,
                subtitle: viewModel.sizeLabel,
                assetRows: viewModel.assetRows,
                groupType: groupType,
                selectedIndexPaths: binding,
                onDelete: { [weak self] in self?.handleDelete() }
            ))
        case 3:
            swiftUIView = AnyView(BaseViewDesign3(
                title: type.rawValue,
                subtitle: viewModel.sizeLabel,
                assetRows: viewModel.assetRows,
                groupType: groupType,
                selectedIndexPaths: binding,
                onDelete: { [weak self] in self?.handleDelete() }
            ))
        default:
            swiftUIView = AnyView(BaseViewDesign1(
                title: type.rawValue,
                subtitle: viewModel.sizeLabel,
                assetRows: viewModel.assetRows,
                groupType: groupType,
                selectedIndexPaths: binding,
                onDelete: { [weak self] in self?.handleDelete() }
            ))
        }

        let vc = UIHostingController(rootView: swiftUIView)
        addChild(vc)
        vc.view.frame = view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(vc.view, at: 0)
        vc.didMove(toParent: self)
        hostingController = vc

        if floatingButton != nil {
            view.bringSubviewToFront(floatingButton)
        }
    }

    private func handleDelete() {
        // Just show alert for preview
        let alert = UIAlertController(title: "Delete", message: "Would delete \(selectedIndexPaths.count) items", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
