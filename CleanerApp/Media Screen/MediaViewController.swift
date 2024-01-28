//
//  MediaViewController.swift
//  CleanerApp
//
//  Created by Manu on 06/01/24.
//

import UIKit
import Combine

class MediaViewController: UIViewController {

    //MARK: - IBOutlet
    @IBOutlet weak var fileAndSizeLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    
    //MARK: - properties
    var viewModel: MediaViewModel!
    private var cancellables: Set<AnyCancellable> = []
    
    //MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupViewModel()
        setupCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    
    
    static func customInit() -> MediaViewController{
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MediaViewController") as! MediaViewController
        return vc
    }
    
    
    //MARK: - IBAction
    @IBAction func backButtonPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    //MARK: -  functions
    
    func setupNavigationItem(){
        
    }
    
    func setupViews(){
        fileAndSizeLabel.superview?.makeCornerRadiusSixtenthOfHeightOrWidth()
    }
    
    func setupViewModel(){
        viewModel = MediaViewModel()
        setPublishers()
    }
    
    func setPublishers(){
        viewModel.$dataSource.sink { [weak self] _ in
            self?.collectionView.reloadData()
        }.store(in: &cancellables)
        
        viewModel.$totalFiles.sink { [weak self] files in
            guard let self else { return }
            self.fileAndSizeLabel.text = "\(files) • \(self.viewModel.totalSize.formatBytes())"
            
        }.store(in: &cancellables)
        
        
        viewModel.$totalSize.sink { [weak self] size in
            guard let self else { return }
            self.fileAndSizeLabel.text = "\(viewModel.totalFiles) • \(size.formatBytes())"
        }.store(in: &cancellables)
    }
    
    func setupCollectionView(){
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.configureCompositionalLayout()
        collectionView.register(UINib(nibName: MediaCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: MediaCollectionViewCell.identifier)
        collectionView.register(UINib(nibName: BaseHeaderCollectionReusableView.identifier, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: BaseHeaderCollectionReusableView.identifier)
        
        collectionView.register(UINib(nibName: MediaHeaderView.identifier, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MediaHeaderView.identifier)
    }
}


extension MediaViewController: UICollectionViewDataSource{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.dataSource.count
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.dataSource[section].cells.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaCollectionViewCell.identifier, for: indexPath) as! MediaCollectionViewCell
        
        let mediaCell = viewModel.dataSource[indexPath.section].cells[indexPath.row]
        cell.configureCell(mediaCell)
        
        return cell
    }
}


extension MediaViewController:UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = viewModel.dataSource[indexPath.section].cells[indexPath.row]
        switch cell.cellType{
            
        case .similarPhoto:
            let vc = SimilarPhotosViewController.customInit()
            navigationController?.pushViewController(vc, animated: true)
            break
        case .duplicatePhoto:
            let vc = DuplicatePhotosViewController.customInit(predicate: viewModel.getPredicate(mediaType: .duplicatePhoto), groupType: .duplicate)
            navigationController?.pushViewController(vc, animated: true)
            break
        case .otherPhoto:
            break
        case .similarScreenshot:
            break
        case .duplicateScreenshot:
            break
        case .otherScreenshot:
            break
        }
    }
}

extension MediaViewController: UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: MediaHeaderView.identifier, for: indexPath) as! MediaHeaderView
        
        headerCell.titleLabel.text = viewModel.dataSource[indexPath.section].title
         return headerCell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.layer.bounds.width, height: 40)
    }
}


