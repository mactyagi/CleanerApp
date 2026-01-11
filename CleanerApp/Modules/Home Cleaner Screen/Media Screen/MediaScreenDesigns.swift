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
                // Stats Header (Design 1 style)
                VStack(spacing: 16) {
                    Text("Media Cleaner")
                        .font(.headline)
                        .foregroundColor(.secondary)

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
                        colors: [Color.blue.opacity(0.15), Color(UIColor.systemBackground)],
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
                                        .font(.headline)
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
    @State private var thumbnails: [UIImage] = []

    var progress: CGFloat {
        guard sectionTotal > 0 else { return 0 }
        return CGFloat(cell.size) / CGFloat(sectionTotal)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Stacked thumbnails
            ZStack {
                ForEach(0..<min(thumbnails.count, 3), id: \.self) { index in
                    Image(uiImage: thumbnails[index])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .offset(x: CGFloat(index * 6), y: CGFloat(index * -3))
                        .shadow(radius: 2)
                }

                if thumbnails.isEmpty {
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
                    .font(.subheadline.bold())

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
                .fill(Color(UIColor.systemBackground))
        )
        .onAppear {
            loadThumbnails()
        }
    }

    private func loadThumbnails() {
        for asset in cell.asset.prefix(3) {
            asset.getImage { image in
                if let image = image {
                    DispatchQueue.main.async {
                        thumbnails.append(image)
                    }
                }
            }
        }
    }
}

// MARK: - Media Screen Hosting Controller
class MediaScreenHostingController: UIViewController {
    private var viewModel: MediaViewModel!
    private var hostingController: UIHostingController<AnyView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        viewModel = MediaViewModel()
        viewModel.fetchAllMediaType()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.setupSwiftUIView()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.fetchAllMediaType()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupSwiftUIView() {
        let dataSource = viewModel.dataSource
        let totalFiles = viewModel.totalFiles
        let totalSize = viewModel.totalSize

        let onCellTapped: (MediaCell) -> Void = { [weak self] cell in
            guard let self = self else { return }

            if cell.cellType.groupType == .other {
                // Use swipe view for Other photos
                let predicate = self.viewModel.getPredicate(mediaType: cell.cellType)
                let context = CoreDataManager.shared.persistentContainer.viewContext
                let assets = CoreDataManager.shared.fetchDBAssets(context: context, predicate: predicate)
                let vc = OtherPhotosSwipeHostingController.create(
                    assets: assets,
                    section: 0,
                    selectedIndexPaths: [],
                    onDismiss: { [weak self] selectedIndexPaths in
                        guard !selectedIndexPaths.isEmpty else { return }

                        let assetIds = selectedIndexPaths.compactMap { indexPath -> String? in
                            guard indexPath.row < assets.count else { return nil }
                            return assets[indexPath.row].assetId
                        }

                        let assetsToDelete = selectedIndexPaths.compactMap { indexPath -> DBAsset? in
                            guard indexPath.row < assets.count else { return nil }
                            return assets[indexPath.row]
                        }

                        PHAssetManager.deleteAssetsById(assetIds: assetIds) { isComplete, error in
                            if isComplete {
                                assetsToDelete.forEach { asset in
                                    CoreDataManager.shared.deleteAsset(asset: asset)
                                }
                                DispatchQueue.main.async {
                                    self?.viewModel.fetchAllMediaType()
                                    self?.setupSwiftUIView()
                                }
                            }
                        }
                    }
                )
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                // Use BaseView for grouped photos
                let vc = BaseViewHostingController.customInit(
                    predicate: self.viewModel.getPredicate(mediaType: cell.cellType),
                    groupType: cell.cellType.groupType,
                    type: cell.cellType
                )
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }

        let onBackTapped: () -> Void = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

        let swiftUIView = MediaScreenView(
            dataSource: dataSource,
            totalFiles: totalFiles,
            totalSize: totalSize,
            onCellTapped: onCellTapped,
            onBackTapped: onBackTapped
        )

        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()

        let vc = UIHostingController(rootView: AnyView(swiftUIView))
        addChild(vc)
        vc.view.frame = view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(vc.view)
        vc.didMove(toParent: self)
        hostingController = vc
    }
}
