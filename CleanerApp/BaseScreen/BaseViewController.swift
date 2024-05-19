//
//  BaseViewController.swift
//  CleanerApp
//
//  Created by Manu on 05/01/24.
//

import UIKit
import Combine
import CoreData


class BaseViewController: UIViewController {

    //MARK: - IBOutlet
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var deleteButtonSuperView: UIView!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var selectedLabel: UILabel!
    
    @IBOutlet weak var deleteSubtitleLabel: UILabel!
    @IBOutlet weak var deleteTitleLabel: UILabel!
    @IBOutlet weak var deleteView: UIView!
    
    //MARK: - variables and properties
    var groupType: PHAssetGroupType!
    var type: MediaCellType!
    var predicate: NSPredicate!
    var selectionBarButtonItem: UIBarButtonItem?
    private var cancellables: Set<AnyCancellable> = []
    var viewModel: BaseViewModel!
    var feedbackGenerator: UIImpactFeedbackGenerator?
    let deleteButtonGradientLayer = CAGradientLayer()


    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupEventsForViewDidLoad()
        setupViewModel()
        setupCollectionView()
        setupViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupEventsForViewAppear()
        setupNavigationBar()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        setupEventsForViewDisappear()
    }
    
    //MARK: - Override functions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.deleteButtonGradientLayer.colors = [UIColor.systemBackground.withAlphaComponent(0.2).cgColor,
                                   UIColor.systemBackground.withAlphaComponent(1).cgColor]
        }
    }

    //MARK: - Static and Class Functions/Properties
    class func customInit(predicate: NSPredicate, groupType: PHAssetGroupType, type: MediaCellType) -> BaseViewController{
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BaseViewController") as! BaseViewController
        vc.predicate = predicate
        vc.groupType = groupType
        vc.type = type
        return vc
    }
    
    //MARK: - IBActions
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        viewModel.deleteAllSelected()
        setupEventsForDeleteButtonPressed()
        
    }
    
    //MARK: - SetupFunction
    func setupEventsForDeleteButtonPressed(){
        switch type {
        case .similarPhoto:
            logEvent(Event.SimilarPhotosScreen.deleteButtonPressed.rawValue, parameter: ["count": viewModel.selectedIndexPath.count])
        case .duplicatePhoto:
            logEvent(Event.SimilarPhotosScreen.deleteButtonPressed.rawValue, parameter: ["count": viewModel.selectedIndexPath.count])
        case .otherPhoto:
            logEvent(Event.OtherPhotosScreen.deleteButtonPressed.rawValue, parameter: ["count": viewModel.selectedIndexPath.count])
        case .similarScreenshot:
            logEvent(Event.SimilarScreenshotScreen.deleteButtonPressed.rawValue, parameter: ["count": viewModel.selectedIndexPath.count])
        case .duplicateScreenshot:
            logEvent(Event.DuplicateScreenshotScreen.deleteButtonPressed.rawValue, parameter: ["count": viewModel.selectedIndexPath.count])
        case .otherScreenshot:
            logEvent(Event.OtherScreenshotScreen.deleteButtonPressed.rawValue, parameter: ["count": viewModel.selectedIndexPath.count])
        case .none:
            break
        }
    }
    
    
    func setupEventsForViewDidLoad(){
        switch type {
        case .similarPhoto:
            logEvent(Event.SimilarPhotosScreen.loaded.rawValue, parameter: nil)
        case .duplicatePhoto:
            logEvent(Event.DuplicatePhotosScreen.loaded.rawValue, parameter: nil)
        case .otherPhoto:
            logEvent(Event.OtherPhotosScreen.loaded.rawValue, parameter: nil)
        case .similarScreenshot:
            logEvent(Event.SimilarScreenshotScreen.loaded.rawValue, parameter: nil)
        case .duplicateScreenshot:
            logEvent(Event.DuplicateScreenshotScreen.loaded.rawValue, parameter: nil)
        case .otherScreenshot:
            logEvent(Event.OtherScreenshotScreen.loaded.rawValue, parameter: nil)
        case .none:
            break
        }
    }
    
    func setupEventsForViewAppear(){
        switch type {
        case .similarPhoto:
            logEvent(Event.SimilarPhotosScreen.appear.rawValue, parameter: nil)
        case .duplicatePhoto:
            logEvent(Event.DuplicatePhotosScreen.appear.rawValue, parameter: nil)
        case .otherPhoto:
            logEvent(Event.OtherPhotosScreen.appear.rawValue, parameter: nil)
        case .similarScreenshot:
            logEvent(Event.SimilarScreenshotScreen.appear.rawValue, parameter: nil)
        case .duplicateScreenshot:
            logEvent(Event.DuplicateScreenshotScreen.appear.rawValue, parameter: nil)
        case .otherScreenshot:
            logEvent(Event.OtherScreenshotScreen.appear.rawValue, parameter: nil)
        case .none:
            break
        }
    }
    
    func setupEventsForViewDisappear(){
        switch type {
        case .similarPhoto:
            logEvent(Event.SimilarPhotosScreen.disappear.rawValue, parameter: nil)
        case .duplicatePhoto:
            logEvent(Event.DuplicatePhotosScreen.disappear.rawValue, parameter: nil)
        case .otherPhoto:
            logEvent(Event.OtherPhotosScreen.disappear.rawValue, parameter: nil)
        case .similarScreenshot:
            logEvent(Event.SimilarScreenshotScreen.disappear.rawValue, parameter: nil)
        case .duplicateScreenshot:
            logEvent(Event.DuplicateScreenshotScreen.disappear.rawValue, parameter: nil)
        case .otherScreenshot:
            logEvent(Event.OtherScreenshotScreen.disappear.rawValue, parameter: nil)
        case .none:
            break
        }
    }
    
    func setupViews() {
        feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
        feedbackGenerator?.prepare()
        titleLabel.text = type.rawValue
        setupDeleteButtonView()
        deleteView.makeCornerRadiusFourthOfHeightOrWidth()
        navigationItem.largeTitleDisplayMode = .never
    }
    
    
    
    func setupCollectionView(){
        collectionView.dataSource = self
        collectionView.delegate = self
        
        let inset = UIEdgeInsets(top: 0, left: 0, bottom:80, right: 0)
        collectionView.contentInset = inset
        
        collectionView.register(UINib(nibName: BaseHeaderCollectionReusableView.identifier, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: BaseHeaderCollectionReusableView.identifier)
        collectionView.register(UINib(nibName: PhotoCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)
        collectionView.collectionViewLayout = GridCollectionViewFlowLayout(columns: 2, topLayoutMargin: 0, bottomLayoutMargin: 5, leftLayoutMargin: 15, spacing: 10, direction: .vertical, isLayoutForCell: true)
    }
    
    func setupViewModel(){
        self.viewModel = BaseViewModel(predicate: predicate, groupType: groupType, type: type)
        setSubscribers()
    }
    
    func setupNavigationBar(){
        selectionBarButtonItem = UIBarButtonItem(title: "Deselect All", style: .plain, target: self, action: #selector(selectionButtonPressed))
        navigationItem.rightBarButtonItem = selectionBarButtonItem
        selectionBarButtonItem?.isEnabled = !viewModel.assetRows.isEmpty
    }

    
    
    func setupDeleteButtonView(){
        deleteButton.makeCornerRadiusCircle()

        deleteButtonGradientLayer.colors = [UIColor.systemBackground.withAlphaComponent(0.2).cgColor,
                                            UIColor.systemBackground.withAlphaComponent(1).cgColor]
        deleteButtonGradientLayer.locations = [0, 0.5]
        deleteButtonGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        deleteButtonGradientLayer.endPoint = CGPoint(x: 0, y: 1)

        deleteButtonGradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: deleteButtonSuperView.bounds.height)

        // Add the gradient layer to the view's layer
        deleteButtonSuperView.layer.insertSublayer(deleteButtonGradientLayer, at: 0)
        
    }
 
    
    @objc func selectionButtonPressed(){
        viewModel.isAllSelected.toggle()
        viewModel.isAllSelected ? viewModel.selectAll() :viewModel.deselectAll()
    }

    
    func setSubscribers(){
        viewModel.$selectedIndexPath.sink(receiveValue: { [weak self] indexPath in
            DispatchQueue.main.async {
                guard let self else { return }
                self.deleteButton.isEnabled = !indexPath.isEmpty
                self.deleteView.backgroundColor = indexPath.isEmpty ? .darkGray3 : .darkBlue
                
                let size = indexPath.reduce(Int64(0)) { $0 + self.viewModel.assetRows[$1.section][$1.row].size}
                self.deleteSubtitleLabel.text = "Clear: \(size.formatBytes())"
                self.deleteTitleLabel.text = "Delete \(indexPath.count) Selected"
                self.selectionBarButtonItem?.isEnabled = !self.viewModel.assetRows.isEmpty
                
                self.collectionView.reloadData()
            }
        })
        .store(in: &cancellables)
        
        viewModel.$sizeLabel.sink { [weak self] sizeLabel in
            DispatchQueue.main.async {
                self?.subTitleLabel.text = sizeLabel
            }
        }.store(in: &cancellables)
        
        viewModel.$isAllSelected.sink { [weak self] isAllSelected in
            guard let self else { return }
            DispatchQueue.main.async {
                self.selectionBarButtonItem?.title = isAllSelected ? "Deselect All" : "Select All"
            }
        }.store(in: &cancellables)
        
        viewModel.$showLoader.sink { [weak self] showLoader in
            DispatchQueue.main.async {
                guard let self else { return }
                showLoader ? self.showFullScreenLoader() : self.hideFullScreenLoader()
            }
        }.store(in: &cancellables)
    }
}


extension BaseViewController: UICollectionViewDataSource{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.assetRows.count
        
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.assetRows[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
        
        let object = viewModel.assetRows[indexPath.section][indexPath.row]
        let isSelected = viewModel.selectedIndexPath.contains(indexPath)
        cell.configureNewCell(asset: object, isSelected: isSelected)
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: { () -> UIViewController? in
            let previewViewController = ImagePreviewViewController()
            previewViewController.image = self.viewModel.assetRows[indexPath.section][indexPath.row].getPHAsset()?.getImage()
            return previewViewController
        }, actionProvider: nil)
        return configuration
    }
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: BaseHeaderCollectionReusableView.identifier, for: indexPath) as! BaseHeaderCollectionReusableView
        headerCell.delegate = self
        headerCell.section = indexPath.section
        headerCell.isAllSelected = viewModel.isAllSelectedAt(section: indexPath.section)
        
        headerCell.countLabel.text = "\(groupType.rawValue.capitalized):\(viewModel.assetRows[indexPath.section].count)"
        
        
        let collectionViewLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout

        collectionViewLayout?.sectionInset = UIEdgeInsets(top: 100, left: 0, bottom: 100, right: 0) // some UIEdgeInset
        (collectionViewLayout?.invalidateLayout())
         return headerCell
    }
}


extension BaseViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.layer.bounds.width, height: groupType == .other ? 0 : 40)
    }
}

extension BaseViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        feedbackGenerator?.impactOccurred()
        collectionView.deselectItem(at: indexPath, animated: false)
        if viewModel.selectedIndexPath.contains(indexPath){
            viewModel.selectedIndexPath.remove(indexPath)
        }else{
            viewModel.selectedIndexPath.insert(indexPath)
        }
        
        
        let headercell = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: indexPath.section)) as? BaseHeaderCollectionReusableView
        headercell?.isAllSelected = viewModel.isAllSelectedAt(section: indexPath.section)
        
        if headercell?.isAllSelected ?? true{
            viewModel.checkForSelection()
        }else{
            viewModel.isAllSelected = false
        }
        collectionView.reloadItems(at: [indexPath])
//        collectionView.reloadSections(IndexSet(integer: indexPath.section))
        
//        viewModel.assetRows[indexPath.section][indexPath.row].isSelected.toggle()
        
    }
}


extension BaseViewController: BaseHeaderCollectionReusableViewDelegate{
    func baseHeaderCollectionReusableView(_ reusableView: BaseHeaderCollectionReusableView, didSelectButtonPressedAt section: Int) {
        
        for index in 0 ..< viewModel.assetRows[section].count{
            let indexPath = IndexPath(row: index, section: section)
            if reusableView.isAllSelected{
                if index == 0{ continue }
                viewModel.selectedIndexPath.insert(indexPath)
                viewModel.checkForSelection()
            }else{
                viewModel.isAllSelected = false
                viewModel.selectedIndexPath.remove(indexPath)
            }
        }
//        collectionView.reloadSections(IndexSet(integer: section))
    }
    
}


