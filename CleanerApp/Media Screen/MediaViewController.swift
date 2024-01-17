//
//  MediaViewController.swift
//  CleanerApp
//
//  Created by Manu on 06/01/24.
//

import UIKit

class MediaViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    var viewModel: MediaViewModel!
    
    //MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
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
    func setupViewModel(){
        viewModel = MediaViewModel()
    }
    
    func setupCollectionView(){
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.configureCompositionalLayout()
        collectionView.register(UINib(nibName: MediaCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: MediaCollectionViewCell.identifier)
    }
}


extension MediaViewController: UICollectionViewDataSource{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.sections.count
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.sections[section].cells.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaCollectionViewCell.identifier, for: indexPath) as! MediaCollectionViewCell
        
        let cellType = viewModel.sections[indexPath.section].cells[indexPath.row]
        cell.configure(cellType: cellType)
        
        return cell
    }
}


extension MediaViewController:UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = viewModel.sections[indexPath.section].cells[indexPath.row]
        switch cell{
            
        case .similarPhoto:
            let vc = SimilarPhotosViewController.customInit()
            navigationController?.pushViewController(vc, animated: true)
            break
        case .duplicatePhoto:
            let vc = DuplicatePhotosViewController.customInit()
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
