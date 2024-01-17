//
//  Extension.swift
//  CleanerApp
//
//  Created by manu on 08/11/23.
//

import Foundation
import Photos
import UIKit
import EventKit
//MARK: - PHAsset

extension PHAsset{
    func getAVAsset(comp: @escaping (_ avAsset: AVAsset?, _ error: Error?) -> ()){
        let manager = PHImageManager.default()
        let option = PHVideoRequestOptions()
//        option.isNetworkAccessAllowed = true
        option.deliveryMode = PHVideoRequestOptionsDeliveryMode.highQualityFormat
        manager.requestAVAsset(forVideo: self, options: option) { avAsset, videoAudio, _ in
            if let avAsset{
                comp(avAsset, nil)
            }else{
                let error = NSError(domain: "AVAsset not found", code: 0)
                comp(nil,error)
            }
        }
    }
    
    static func findPHAssetByLocalIdentifier(localIdentifier: String) -> PHAsset? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier = %@", localIdentifier)

        let result = PHAsset.fetchAssets(with: fetchOptions)

        if let asset = result.firstObject {
            return asset
        } else {
            print("PHAsset not found for local identifier: \(localIdentifier)")
            return nil
        }
    }
    
    
    func delete(completionHandler:@escaping (_ isComplete: Bool, _ error: Error?) -> ()){
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets([self] as NSArray)
        } completionHandler: { isComplete, error in
            completionHandler(isComplete, error)
        }
    }
    
    func getSize() -> Int64? {
        let resources = PHAssetResource.assetResources(for: self)
        guard let resource = resources.first,
              let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong
        else { return nil }
        return Int64(bitPattern: UInt64(unsignedInt64))
    }
    
    
    func getImage() -> UIImage?{
        let manager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        let size = CGSize(width: UIScreen.main.bounds.width/2, height: UIScreen.main.bounds.width/2)
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        var img: UIImage?
        manager.requestImage(for: self, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, _ in
        img = image
        }
        return img
    }
    
    func getImage(comp: @escaping(_ image: UIImage?) -> ()){
        let manager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        let size = CGSize(width: UIScreen.main.bounds.width/2, height: UIScreen.main.bounds.width/2)
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        manager.requestImage(for: self, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, _ in
        comp(image)
        }
    }
}


extension UInt64 {
    func convertToFileString() -> String {
        var convertedValue: Double = Double(self)
        var multiplyFactor = 0
        let tokens = ["bytes", "KB", "MB", "GB", "TB", "PB",  "EB",  "ZB", "YB"]
        while convertedValue > 1000 {
            convertedValue /= 1000
            multiplyFactor += 1
        }
        return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
    }
}

extension Int64 {
    func convertToFileString() -> String {
        var convertedValue: Double = Double(self)
        var multiplyFactor = 0
        let tokens = ["bytes", "KB", "MB", "GB", "TB", "PB",  "EB",  "ZB", "YB"]
        while convertedValue > 1000 {
            convertedValue /= 1000
            multiplyFactor += 1
        }
        return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
    }
    
    func formatBytes() -> String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useAll]
        byteCountFormatter.countStyle = .file

        return byteCountFormatter.string(fromByteCount: Int64(self))
    }
}


extension UInt64{
    func formatBytes() -> String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useAll]
        byteCountFormatter.countStyle = .file

        return byteCountFormatter.string(fromByteCount: Int64(self))
    }
}




extension UIViewController{
    static var className : String{
        return String(describing: type(of: self))
    }
    
    func showLoader() {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
       activityIndicator.startAnimating()
       view.isUserInteractionEnabled = false // Disable user interaction while the loader is displayed
    }
}


extension UIView{
    func addBlurEffect(style: UIBlurEffect.Style, alpha: CGFloat){
        let blurEffect = UIBlurEffect(style: style)
        let bluredEffectView = UIVisualEffectView(effect: blurEffect)
        bluredEffectView.frame = self.bounds
        bluredEffectView.alpha = alpha
        bluredEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(bluredEffectView)
    }
    
    func dropShadow() {
        layer.masksToBounds = true
        layer.shadowColor = UIColor.label.cgColor
        layer.shadowOffset = CGSizeMake(0, 3)
        layer.shadowOpacity = 1
        layer.shadowRadius = 1
    }
    
    func makeCircleRadius(){
        layer.cornerRadius = frame.height / 2
    }
    
    func activityStartAnimating(activityColor: UIColor = .gray, backgroundColor: UIColor = .clear, style: UIActivityIndicatorView.Style = .medium) {
        let backgroundView = UIView()
        backgroundView.frame = CGRect.init(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        backgroundView.backgroundColor = backgroundColor
        backgroundView.tag = 475647
        
        var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
        activityIndicator = UIActivityIndicatorView(frame: CGRect.init(x: 0, y: 0, width: 50, height: 50))
        activityIndicator.center = self.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = UIActivityIndicatorView.Style.large
        activityIndicator.color = activityColor
        activityIndicator.startAnimating()
        self.isUserInteractionEnabled = false
        
        backgroundView.addSubview(activityIndicator)

        self.addSubview(backgroundView)
    }

    func activityStopAnimating() {
        if let background = viewWithTag(475647){
            background.removeFromSuperview()
        }
        self.isUserInteractionEnabled = true
    }
}


extension UIStoryboard{
    static var main: UIStoryboard{
        UIStoryboard(name: "Main", bundle: nil)
    }
    
    static var VideoCompress: UIStoryboard{
        UIStoryboard(name: "VideoCompress", bundle: nil)
    }
    
    static var secretSpace: UIStoryboard{
        UIStoryboard(name: "SecretSpace", bundle: nil)
    }
}


extension Date{
    func toString(formatType: DateFormats = .decode) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatType.rawValue
        return dateFormatter.string(from: self)
    }
    
    enum DateFormats : String {
        case ddMMyyyyhhmmss = "ddMMyyyy HH:mm:ss"
        case ddMMMyyyy = "ddMMMyyyy"
        case yyyyMMdd = "yyyy-MM-dd"
        case MMddyy = "MM-dd-yyyy"
        case decoderFormat = "yyyy-MM-dd'T'HH:mm:SSZ"
        case decoderFormat1 = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        case decoderFormatWith6S = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        case decode = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        case dMMM = "d MMM"
        case log = "yyyy-MM-dd HH:mm:ss.SSS "
        case MMMdyyyyhmma = "MMM d, yyyy, h:mm a"
        case MMMdyyyy = "MMM d, yyyy"
        case MMMMdyyyy = "MMMM d, yyyy"
        case ddMMyyyy = "dd/MM/yyyy"
        case mmmdhmma = "MMM d, h:mm a"
        case ddmmmyyyyhhmma = "dd-MMM-yyyy hh:mm a"
        case hmma = "h:mm a"
        case yyyy = "yyyy"
        case ddmmmyyyy = "dd-MMM-yyyy"
    }
}

extension EKEvent{
    var year: String {
        startDate.toString(formatType: .yyyy)
    }
}

extension EKReminder{
    var year: String{
        (creationDate ?? Date()).toString(formatType: .yyyy)
    }
}


extension UICollectionView{
    func configureCompositionalLayout(){
        let mainItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/2), heightDimension: .fractionalHeight(1)))
        mainItem.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        
        let verticalPairItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1/2)))
        verticalPairItem.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        
        let verticalPairGroup = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/2), heightDimension: .fractionalHeight(1)), subitems: [verticalPairItem, verticalPairItem])
//        verticalPairGroup.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
        
        let mainWithVerticalPairGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(1)), subitems: [mainItem, verticalPairGroup])
        mainWithVerticalPairGroup.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
        
        // second style
        let horizontalPairItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/2), heightDimension: .fractionalHeight(1)))
        horizontalPairItem.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        
        let horizontalPairGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(1/2)), subitems: [horizontalPairItem, horizontalPairItem])
        horizontalPairGroup.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
        
//        let fullItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(2/3)))

        
        let nestedGroup = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(3/2)), subitems: [horizontalPairGroup, mainWithVerticalPairGroup])
        
        let section = NSCollectionLayoutSection(group: nestedGroup)
        let layout = UICollectionViewCompositionalLayout(section: section)
        self.collectionViewLayout = layout
    }
}



