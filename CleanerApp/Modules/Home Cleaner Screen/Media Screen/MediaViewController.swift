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
        logEvent(Event.MediaScreen.loaded.rawValue, parameter: nil)
        setupViews()
        setupViewModel()
        setupCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationAndTabBar(isScreenVisible: false)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        NotificationCenter.default.addObserver(self, selector: #selector(progressFractionCompleted(notification:)), name: Notification.Name.updateData, object: nil)
        viewModel.fetchAllMediaType()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logEvent(Event.MediaScreen.appear.rawValue, parameter: nil)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        logEvent(Event.MediaScreen.disappear.rawValue, parameter: nil)
    }
    
    
    static func customInit() -> Self{
        UIStoryboard.media.instantiateViewController(withIdentifier: Self.className) as! Self
    }
    
    
    //MARK: - IBAction
    @IBAction func backButtonPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    //MARK: -  functions
    
    
    @objc func progressFractionCompleted(notification: Notification) {
        viewModel.fetchAllMediaType()
    }
    
    
    func setupNavigationItem(){
        
    }
    
    func setupViews(){
        fileAndSizeLabel.superview?.makeCornerRadiusSixtenthOfHeightOrWidth()
        let swipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
            swipeGestureRecognizer.edges = .left // Specify the edge for swipe (e.g., left edge)
            view.addGestureRecognizer(swipeGestureRecognizer)
    }
    
    func setupViewModel(){
        viewModel = MediaViewModel()
        setPublishers()
    }
    
    func setPublishers(){
        viewModel.$dataSource.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
            }
            
        }.store(in: &cancellables)
        
        viewModel.$totalFiles.sink { [weak self] files in
            guard let self else { return }
            DispatchQueue.main.async {
                self.fileAndSizeLabel.text = "\(files) • \(self.viewModel.totalSize.formatBytes())"
                
            }
        }.store(in: &cancellables)
        
        
        viewModel.$totalSize.sink { [weak self] size in
            guard let self else { return }
            DispatchQueue.main.async {
                self.fileAndSizeLabel.text = "\(self.viewModel.totalFiles) • \(size.formatBytes())"
            }
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
    
    @objc func handleSwipeGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .began {
            navigationController?.popViewController(animated: true)
        }
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
        let vc = BaseViewController.customInit(predicate: viewModel.getPredicate(mediaType: cell.cellType), groupType: cell.cellType.groupType, type: cell.cellType)
        navigationController?.pushViewController(vc, animated: true)
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


