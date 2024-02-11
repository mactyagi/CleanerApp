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
    
    //MARK: - variables and properties
    var groupType: PHAssetGroupType!
    var predicate: NSPredicate!
    var selectionBarButtonItem: UIBarButtonItem?
    private var cancellables: Set<AnyCancellable> = []
    var viewModel: BaseViewModel!
    

    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupCollectionView()
//        LoadSaveData()
        setupViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupNavigationBar()
    }
    
    
    //MARK: - Static and Class Functions/Properties
    class func customInit(predicate: NSPredicate, groupType: PHAssetGroupType) -> BaseViewController{
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BaseViewController") as! BaseViewController
        vc.predicate = predicate
        vc.groupType = groupType
        return vc
    }
    
    //MARK: - IBActions
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        viewModel.deleteAllSelected()
    }
    
    //MARK: - SetupFunction
    func setupViews() {
        titleLabel.text = groupType.rawValue.capitalized
        setupDeleteButtonView()
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
        self.viewModel = BaseViewModel(predicate: predicate, groupType: groupType)
        setSubscribers()
    }
    
    func setupNavigationBar(){
        selectionBarButtonItem = UIBarButtonItem(title: "Deselect All", style: .plain, target: self, action: #selector(selectionButtonPressed))
        navigationItem.rightBarButtonItem = selectionBarButtonItem
    }

    
    
    func setupDeleteButtonView(){
        deleteButton.makeCornerRadiusCircle()
        
        let gradientLayer = CAGradientLayer()
        
        gradientLayer.colors =  [
            UIColor.veryLightBlueAndDarkGray.withAlphaComponent(0).cgColor,
            UIColor.veryLightBlueAndDarkGray.withAlphaComponent(1).cgColor
        ]
        gradientLayer.locations = [0, 0.6]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)

        gradientLayer.frame = deleteButtonSuperView.bounds

        // Add the gradient layer to the view's layer
        deleteButtonSuperView.layer.insertSublayer(gradientLayer, at: 0)
        
    }
 
    
    @objc func selectionButtonPressed(){
        viewModel.isAllSelected.toggle()
        viewModel.isAllSelected ? viewModel.selectAll() :viewModel.deselectAll()
    }

    
    func setSubscribers(){
        viewModel.$selectedIndexPath.sink(receiveValue: { [weak self] indexPath in
            DispatchQueue.main.async {
                self?.deleteButton.isEnabled = !indexPath.isEmpty
                self?.deleteButton.backgroundColor = indexPath.isEmpty ? .darkGray3 : .darkBlue
                self?.collectionView.reloadData()
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
