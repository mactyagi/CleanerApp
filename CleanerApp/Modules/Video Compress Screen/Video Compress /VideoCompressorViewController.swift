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
    //MARK: - Variables
    var viewModel: VideoCompressViewModel!
    private var subscribers:[AnyCancellable] = []
    private var shouldReloadData = false

    //MARK: - LifeCycles
    override func viewDidLoad() {
        super.viewDidLoad()
        logEvent(Event.CompressorScreen.loaded.rawValue, parameter: nil)
        viewModel = VideoCompressViewModel()
        setSubscribers()
        setupCollectionView()
        viewModel.fetchData()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationAndTabBar(isScreenVisible: true)

        if shouldReloadData{
            viewModel.fetchData()
            shouldReloadData.toggle()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logEvent(Event.CompressorScreen.appear.rawValue, parameter: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = true
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        logEvent(Event.CompressorScreen.disappear.rawValue, parameter: nil)
    }
    
    
    //MARK: - static variables and function
    static func initWith() -> VideoCompressorViewController{
        let vc = UIStoryboard.videoCompress.instantiateViewController(withIdentifier: VideoCompressorViewController.className) as! VideoCompressorViewController
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
        headerView.sizeButtonlabel.setTitle(self.viewModel.totalCompressSize.convertToFileString(), for: .normal)
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 0, height: 60)
    }
}

extension VideoCompressorViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Use SwiftUI Classic Card design
        let vc = CompressQualitySelectionHostingController(compressAsset: viewModel.compressVideoModel[indexPath.row])
        vc.dataChangedHandler = {
            self.shouldReloadData = true
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}


//MARK: -  Subscribers
extension VideoCompressorViewController{
    func setSubscribers(){
        viewModel.$compressVideoModel.receive(on: DispatchQueue.main).sink { error in
            print(error)
        } receiveValue: { data in
            DispatchQueue.main.async {
                logEvent(Event.CompressorScreen.videoCount.rawValue, parameter: ["count":data.count])
                self.collectionView.reloadData()
                self.secondaryLabel.text = "Videos \(data.count) • \(self.viewModel.totalSize.convertToFileString())"
            }
        }.store(in: &subscribers)
        
        viewModel.$isLoading.sink { isLoading in
            DispatchQueue.main.async {
                logEvent(Event.CompressorScreen.loadingStatus.rawValue, parameter: ["isLoading": isLoading])
                self.collectionView.isHidden = isLoading
                isLoading ? self.view.activityStartAnimating() : self.view.activityStopAnimating()
            }
        }.store(in: &subscribers)
    }
}
