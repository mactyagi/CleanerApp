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
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupCollectionView()
        
    }
    static func customInit() -> MediaViewController{
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MediaViewController") as! MediaViewController
        return vc
    }
    
    func setupViewModel(){
        viewModel = MediaViewModel()
    }
    
    func setupCollectionView(){
        collectionView.dataSource = self
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
