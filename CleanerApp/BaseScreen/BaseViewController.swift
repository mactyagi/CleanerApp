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

    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var deleteButtonSuperView: UIView!
    @IBOutlet weak var subTitleLabel: UILabel!
    var fetchResultViewController: NSFetchedResultsController<DBAsset>!
    var groupType: PHAssetGroupType!
    var predicate: NSPredicate!
    var isAllSelected: Bool = true{
        didSet{
            selectionBarButtonItem?.title = isAllSelected ? "Deselect All" : "Select All"
        }
    }
    var selectionBarButtonItem: UIBarButtonItem?
    private var cancellables: Set<AnyCancellable> = []
    var viewModel: BaseViewModel!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupCollectionView()
        LoadSaveData()
        setupViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupNavigationBar()
    }
    
    
    class func customInit(predicate: NSPredicate, groupType: PHAssetGroupType) -> BaseViewController{
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BaseViewController") as! BaseViewController
        vc.predicate = predicate
        vc.groupType = groupType
        return vc
    }
    
    func setupViews() {
        titleLabel.text = groupType.rawValue.capitalized
        setupDeleteButtonView()
    }
    
    func reloadData() {
        guard let sections = fetchResultViewController.sections?.count else { return }
        UIView.animate(withDuration: 0.3, animations: {
                self.collectionView.performBatchUpdates({
                    for section in 0 ..< sections{
                        self.collectionView.reloadSections(IndexSet(integer: section))
                    }
                    
                }, completion: nil)
            })
        }
    
    
    
    func updateSubtitleLabel(){
        guard let dbAssets = fetchResultViewController.fetchedObjects else { return }
        var size = dbAssets.reduce(0) { $0 + $1.size }
//    Videos: 6 • 733 MB
        subTitleLabel.text = "Photos: \(dbAssets.count) • \(size.formatBytes())"
    }
    
    func setupCollectionView(){
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UINib(nibName: BaseHeaderCollectionReusableView.identifier, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: BaseHeaderCollectionReusableView.identifier)
        collectionView.register(UINib(nibName: PhotoCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)
        collectionView.collectionViewLayout = GridCollectionViewFlowLayout(columns: 2, topLayoutMargin: 0, bottomLayoutMargin: 0, leftLayoutMargin: 15, spacing: 10, direction: .vertical, isLayoutForCell: true)
    }
    
    func setupViewModel(){
        self.viewModel = BaseViewModel(predicate: predicate)
        setSubscribers()
    }
    
    func setupNavigationBar(){
        selectionBarButtonItem = UIBarButtonItem(title: "Deselect All", style: .plain, target: self, action: #selector(selectionButtonPressed))
        navigationItem.rightBarButtonItem = selectionBarButtonItem
    }
    
    @objc func selectionButtonPressed(){
        isAllSelected.toggle()
        isAllSelected ? selectAll() : deselectAll()
    }
    
    func setupDeleteButtonView(){
        deleteButton.makeCircleRadius()
        
        let gradientLayer = CAGradientLayer()
        
        gradientLayer.colors =  [
            UIColor.systemBackground.withAlphaComponent(0).cgColor,
            UIColor.systemBackground.withAlphaComponent(1).cgColor
        ]
        gradientLayer.locations = [0, 0.6]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)

        gradientLayer.frame = deleteButtonSuperView.bounds

        // Add the gradient layer to the view's layer
        deleteButtonSuperView.layer.insertSublayer(gradientLayer, at: 0)
        
    }
    
    func LoadSaveData(){
        if fetchResultViewController == nil{
            let request = DBAsset.fetchRequest()
            let subGroupSort = NSSortDescriptor(key: "subGroupId", ascending: true)
            let dateSort = NSSortDescriptor(key: "creationDate", ascending: true)
            request.sortDescriptors = [dateSort]
            
            if let predicate{
                request.predicate = predicate
            }
            
            fetchResultViewController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataManager.shared.persistentContainer.viewContext, sectionNameKeyPath: "subGroupId", cacheName: nil)
            
            fetchResultViewController.delegate = self
            
            do{
                try fetchResultViewController.performFetch()
                selectAll()
                updateSubtitleLabel()
            } catch{
                print(error)
            }
        }
    }
    
    func selectAll(){
        guard let sections = fetchResultViewController.sections else { return }
        for (index,section) in sections.enumerated() {
            let rowsCount = section.numberOfObjects
            for index2 in 0 ..< rowsCount{
                if index2 > 0{
                    let indexpath = IndexPath(row: index2, section: index)
                    viewModel.selectedIndexPath.insert(indexpath)
                }
            }
        }
//        collectionView.reloadData()
        reloadData()
    }

    
    func deselectAll(){
        viewModel.selectedIndexPath.removeAll()
//        collectionView.reloadData()
        reloadData()
    }
    
    func setSubscribers(){
        viewModel.$reloadCollectionView.sink { [weak self] isreload in
            if isreload{
//                self?.collectionView.reloadData()
            }
        }
        .store(in: &cancellables)
    }
}


extension BaseViewController: UICollectionViewDataSource{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchResultViewController.sections?.count ?? 0
        
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return viewModel.assetRows[section].count
        return fetchResultViewController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
        
        //        let asset = viewModel.assetRows[indexPath.section][indexPath.row]
        //        cell.configureNewCell(asset: asset)
        
        let object = fetchResultViewController.object(at: indexPath)
        let isSelected = viewModel.selectedIndexPath.contains(indexPath)
        cell.configureNewCell(asset: object, isSelected: isSelected)
        return cell
    }
    
    func checkForSelection(){
        guard let sectionsCount = fetchResultViewController.sections?.count else { return }
        for section in 0 ..< sectionsCount{
            let isSectionSelected = isAllSelectedAt(section: section)
            if !isSectionSelected{
                isAllSelected = false
                return
            }
        }
        isAllSelected = true
    }
    
    func isAllSelectedAt(section: Int) -> Bool{
        let rowsCount = fetchResultViewController.sections?[section].numberOfObjects ?? 0
        for index in 1 ..< rowsCount{
            let currentIndexPath = IndexPath(row: index, section: section)
            if !viewModel.selectedIndexPath.contains(currentIndexPath){
                return false
            }
        }
        return true
    }
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: BaseHeaderCollectionReusableView.identifier, for: indexPath) as! BaseHeaderCollectionReusableView
        headerCell.delegate = self
        headerCell.section = indexPath.section
        headerCell.isAllSelected = isAllSelectedAt(section: indexPath.section)
        
        headerCell.countLabel.text = "\(groupType.rawValue.capitalized):\(fetchResultViewController.sections?[indexPath.section].numberOfObjects ?? 0)"
         return headerCell
    }
}


extension BaseViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.layer.bounds.width, height: 40)
    }
}

extension BaseViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        collectionView.deselectItem(at: indexPath, animated: false)
        if viewModel.selectedIndexPath.contains(indexPath){
            viewModel.selectedIndexPath.remove(indexPath)
        }else{
            viewModel.selectedIndexPath.insert(indexPath)
        }
        
        
        let headercell = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: indexPath.section)) as? BaseHeaderCollectionReusableView
        headercell?.isAllSelected = isAllSelectedAt(section: indexPath.section)
        
        if headercell?.isAllSelected ?? true{
            checkForSelection()
        }else{
            self.isAllSelected = false
        }
        collectionView.reloadItems(at: [indexPath])
//        collectionView.reloadSections(IndexSet(integer: indexPath.section))
        
//        viewModel.assetRows[indexPath.section][indexPath.row].isSelected.toggle()
        
    }
}

extension BaseViewController: NSFetchedResultsControllerDelegate{
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates(nil)
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type{
            
        case .insert:
            collectionView?.insertSections(indexSet)
        case .delete:
            collectionView?.deleteSections(indexSet)
        default:
            break
        }
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            collectionView?.insertItems(at: [newIndexPath!])
        case .delete:
            collectionView?.deleteItems(at: [indexPath!])
        case .move:
            collectionView?.moveItem(at: indexPath!, to: newIndexPath!)
        case .update:
            collectionView?.reloadItems(at: [indexPath!])
        @unknown default:
            break
        }
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.performBatchUpdates(nil, completion: nil)
    }
}


extension BaseViewController: BaseHeaderCollectionReusableViewDelegate{
    func baseHeaderCollectionReusableView(_ reusableView: BaseHeaderCollectionReusableView, didSelectButtonPressedAt section: Int) {
        
        guard let rowsCount = fetchResultViewController.sections?[section].numberOfObjects else { return }
        for index in 0 ..< rowsCount{
            let indexPath = IndexPath(row: index, section: section)
            if reusableView.isAllSelected{
                if index == 0{ continue }
                checkForSelection()
                viewModel.selectedIndexPath.insert(indexPath)
            }else{
                isAllSelected = false
                viewModel.selectedIndexPath.remove(indexPath)
            }
        }
        collectionView.reloadSections(IndexSet(integer: section))
    }
    
    
}
