//
//  CompressQualitySelectionViewController.swift
//  CleanerApp
//
//  Created by manu on 12/11/23.
//

import UIKit
import AVFoundation
import AVKit
import Combine
class CompressQualitySelectionViewController: UIViewController {

    //MARK: - @IBOutlets
    
    
    @IBOutlet weak var lowAlphaView: UIView!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var mainCenterVIew: UIView!
    @IBOutlet weak var BeforeSizeAndNowSizeSuperView: UIView!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var CompressButton: UIButton!
    @IBOutlet weak var deleteOriginalButton: UIButton!
    @IBOutlet weak var keepOriginalButton: UIButton!
    @IBOutlet weak var nowSizeLabel: UILabel!
    @IBOutlet weak var beforeSizeLabel: UILabel!
    @IBOutlet weak var CompleteView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var processingView: UIView!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var DetailNowSizeLabel: UILabel!
    @IBOutlet weak var detailCompressSizeLabel: UILabel!
    @IBOutlet weak var segmentSuperView: UIView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    //MARK: - Variables
    var viewModel: CompressQualitySelectionViewModel!
    private var avPlayerViewController: AVPlayerViewController!
    private var cancelableSubscribers:[AnyCancellable] = []
    //MARK: - Life cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setSubscribers()
        beforeCompressUI()
        setupVideoPlayer(asset: viewModel.compressAsset.avAsset)
    }
    
    
    //MARK: - static functions
    static func initWith(compressAsset: CompressVideoModel) -> CompressQualitySelectionViewController{
        let destinationPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("compressed.mp4")
        try? FileManager.default.removeItem(at: destinationPath)
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CompressQualitySelectionViewController") as! CompressQualitySelectionViewController
        vc.viewModel = CompressQualitySelectionViewModel(compressAsset: compressAsset)
        vc.viewModel.compressAsset.compressor.destinationURL = destinationPath
        return vc
    }
    
    //MARK: - @IBAction
    @IBAction func compressButtonPressed(_ sender: UIButton) {
        viewModel.compressAsset.compressor.compressVideo { progress in
            self.progressView.setProgress(Float(progress.fractionCompleted), animated: true)
        } completion: { CompressionResult in
            switch CompressionResult{
            case .onStart:
                print("Started")
                self.duringCompressUI()
            case .onSuccess(let url):
                self.viewModel.saveVideoToPhotosLibrary(videoURL: url) { size, saveError in
                    if let saveError{
                        print(saveError)
                    }else{
                        DispatchQueue.main.async{
                            self.nowSizeLabel.text = size.convertToFileString()
                            self.subtitleLabel.text = "Space saved: \((self.viewModel.compressAsset.originalSize - size).convertToFileString())"
                            self.afterCompressUI()
                        }
                    }
                }
            case .onFailure( let error):
                print(error)
            case .onCancelled:
                print("cancelled")
            }
        }
    }
    
    @IBAction func keepOriginalButtonPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteOriginalButtonPressed(_ sender: UIButton) {
        sender.isEnabled = false
        viewModel.compressAsset.phAsset.delete { isComplete, error in
            if let error{
                print(error.localizedDescription)
            }else if isComplete{
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    @IBAction func segmentControlChanges(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex{
        case 0:
            viewModel.optimalQualitySelected()
            break
        case 1:
            viewModel.MediumQualitySelected()
            break
        case 2:
            viewModel.MaxQualitySelected()
            break
        default:
            break
        }
    }
    
    
    //MARK: - Functions
    func setup(){
        playerView.layer.cornerRadius = 20
        detailView.layer.cornerRadius = 20
        segmentSuperView.layer.cornerRadius = 20
        CompleteView.layer.cornerRadius = 20
        processingView.layer.cornerRadius = 20
        BeforeSizeAndNowSizeSuperView.layer.cornerRadius = 20
        mainCenterVIew.layer.cornerRadius = 20
        blurView.layer.cornerRadius = 20
        blurView.layer.cornerRadius = 20
        lowAlphaView.layer.cornerRadius = 20
//        blurView.addBlurEffect(style: .dark, alpha: 1)
        let selectedTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            segmentControl.setTitleTextAttributes(selectedTitleTextAttributes, for: .selected)
    }
    
    
    
    private func setupVideoPlayer(asset: AVAsset) {
        // configure player
        avPlayerViewController = AVPlayerViewController()
        let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        player.externalPlaybackVideoGravity = .resizeAspectFill
        avPlayerViewController.player = player
        addChild(avPlayerViewController)
        avPlayerViewController.view.backgroundColor = UIColor.primaryCell
        avPlayerViewController.view.layer.cornerRadius = playerView.layer.cornerRadius
        avPlayerViewController.contentOverlayView?.layer.cornerRadius = 20
        playerView.addSubview(avPlayerViewController.view)
        avPlayerViewController.view.frame = CGRect(x: 0, y: 0, width: playerView.frame.width, height: playerView.frame.height)
        avPlayerViewController.didMove(toParent: self)
        avPlayerViewController.player?.play()
    }
    
    
    func beforeCompressUI(){
        DispatchQueue.main.async {
            self.lowAlphaView.isHidden = true
            self.deleteOriginalButton.isHidden = true
            self.keepOriginalButton.isHidden = true
            self.detailLabel.isHidden = true
            self.CompleteView.isHidden = true
            self.processingView.isHidden = true
            self.CompressButton.isHidden = false
            self.detailView.isHidden = false
            self.segmentSuperView.isHidden = false
        }
        
    }
    
    func duringCompressUI(){
        DispatchQueue.main.async {
            self.navigationItem.setHidesBackButton(true, animated: true)
            self.lowAlphaView.isHidden = false
            self.avPlayerViewController.player?.pause()
            self.deleteOriginalButton.isHidden = false
            self.deleteOriginalButton.isEnabled = false
            self.keepOriginalButton.isHidden = false
            self.keepOriginalButton.isEnabled = false
            self.detailLabel.isHidden = false
            self.detailLabel.text = "Dont't close the app. Otherwise, the video won't be compressed."
            self.subtitleLabel.text = "Compressing Video . . ."
            self.CompleteView.isHidden = true
            self.processingView.isHidden = false
            self.CompressButton.isHidden = true
            self.detailView.isHidden = true
            self.segmentSuperView.isHidden = true
        }
        
    }
    
    func afterCompressUI(){
        DispatchQueue.main.async {
            self.navigationItem.setHidesBackButton(false, animated: true)
            self.lowAlphaView.isHidden = false
            self.deleteOriginalButton.isHidden = false
            self.deleteOriginalButton.isEnabled = true
            self.keepOriginalButton.isHidden = false
            self.keepOriginalButton.isEnabled = true
            self.detailLabel.isHidden = false
            self.detailLabel.text = "What do you want to do with the original video?"
            self.CompleteView.isHidden = false
            self.processingView.isHidden = true
            self.CompressButton.isHidden = true
            self.detailView.isHidden = true
            self.segmentSuperView.isHidden = true
        }
        
    }
}


extension CompressQualitySelectionViewController{
    func setSubscribers(){
        viewModel.$compressAsset.receive(on: DispatchQueue.main).sink { error in
            print(error)
        } receiveValue: { compressAsset in
            self.DetailNowSizeLabel.text = compressAsset.originalSize.convertToFileString()
            self.beforeSizeLabel.text = compressAsset.originalSize.convertToFileString()
            let compressSize = compressAsset.reduceSize
            self.detailCompressSizeLabel.text = compressSize.convertToFileString()
            let attributes = [NSAttributedString.Key.foregroundColor: UIColor.systemBlue]
            let attribute2 = [NSAttributedString.Key.foregroundColor: UIColor.label]
            let attributedText = NSMutableAttributedString(string: "You will save about ", attributes: attributes)
            let secondAttributedText = NSAttributedString(string: (compressAsset.originalSize - compressSize).convertToFileString(), attributes: attribute2)
            attributedText.append(secondAttributedText)
            self.subtitleLabel.attributedText = attributedText
        }.store(in: &cancelableSubscribers)
    }
}
