//
//  VideoCompressorViewController.swift
//  CleanerApp
//
//  Created by manu on 08/11/23.
//

import UIKit
import Combine

class VideoCompressorViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var secondaryLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var totalCompressSize: UIButton!
    //MARK: - Variables
    var viewModel: VideoCompressViewModel!
    private var subscribers:[AnyCancellable] = []
    
    //MARK: - LifeCycles
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = VideoCompressViewModel()
        setSubscribers()
        setupCollectionView()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchData()
    }
    
    
    //MARK: - static variables and function
    static let identifer = "VideoCompressorViewController"
    static func initWith() -> VideoCompressorViewController{
        let vc = UIStoryboard(name: "VideoCompress", bundle: nil).instantiateViewController(withIdentifier: identifer) as! VideoCompressorViewController
        return vc
    }
    
    //MARK: - Functions
    func setupCollectionView(){
        collectionView.register(UINib(nibName: CompressCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: CompressCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = GridCollectionViewFlowLayout(columns: 2, topLayoutMargin: 10, bottomLayoutMargin: 0, leftLayoutMargin: 0, spacing: 10, direction: .vertical, isLayoutForCell: false)
    }
}


extension VideoCompressorViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.compressVideoModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CompressCollectionViewCell.identifier, for: indexPath) as! CompressCollectionViewCell
        cell.configureCell(compressAsset: viewModel.compressVideoModel[indexPath.row])
        return cell
    }
}

extension VideoCompressorViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CompressVideosHeaderView.identifier, for: indexPath) as! CompressVideosHeaderView
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 0, height: 60)
    }
}

extension VideoCompressorViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = CompressQualitySelectionViewController.initWith(compressAsset: viewModel.compressVideoModel[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }
}


//MARK: -  Subscribers
extension VideoCompressorViewController{
    func setSubscribers(){
        viewModel.$compressVideoModel.receive(on: DispatchQueue.main).sink { error in
            print(error)
        } receiveValue: { data in
            self.collectionView.reloadData()
            self.secondaryLabel.text = "Videos \(data.count) • \(self.viewModel.totalSize.convertToFileString())"
            self.totalCompressSize.setTitle(self.viewModel.totalCompressSize.convertToFileString(), for: .normal)
        }.store(in: &subscribers)
    }
}
