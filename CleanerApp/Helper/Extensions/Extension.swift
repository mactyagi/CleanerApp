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
    func getAVAsset(comp: @escaping (_ avAsset: AVAsset?) -> ()){
        let manager = PHImageManager.default()
        let option = PHVideoRequestOptions()
//        option.isNetworkAccessAllowed = true
        option.deliveryMode = PHVideoRequestOptionsDeliveryMode.highQualityFormat
        manager.requestAVAsset(forVideo: self, options: option) { avAsset, videoAudio, _ in
            if let avAsset{
                comp(avAsset)
            }else{
                logErrorString(errorString: "AVAsset not found", VCName: "PHAsset", functionName: #function, line: #line)
                comp(nil)
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
            logErrorString(errorString: "PHAsset not found for local identifier: \(localIdentifier)", VCName: "PHAsset", functionName: #function, line: #line)
            return nil
        }
    }
    
    
    func delete(completionHandler:@escaping (_ isComplete: Bool, _ error: Error?) -> ()){
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets([self] as NSArray)
        } completionHandler: { isComplete, error in
            if let error{
                logError(error: error as NSError, VCName: "PHAsset", functionName: #function, line: #line)
            }
            
            completionHandler(isComplete, error)
        }
    }
    
    func getSize() -> Int64? {
        let resources = PHAssetResource.assetResources(for: self)
        guard let resource = resources.first,
              let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong
        else {
            logErrorString(errorString: "Not able to get file Size", VCName: "PHAsset", functionName: #function, line: #line)
            return nil
        }
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
        if img == nil{
            logErrorString(errorString: "Can not get image from PHAsset", VCName: "PHAsset", functionName: #function, line: #line)
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
            if image == nil{
                logErrorString(errorString: "Can not get image from PHAsset by excaping", VCName: "PHAsset", functionName: #function, line: #line)
            }
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
    
    func formatBytesWithRoundOff() -> String{
        let formatedString = self.formatBytes()
        let tuple = extractNumericAndNonNumericParts(from: formatedString)
        let numericPart = Int(ceil(Double(tuple.numericPart ?? "") ?? 0))
        return "\(numericPart)\(tuple.nonNumericPart ?? "")"
    }
    
    func extractNumericAndNonNumericParts(from formattedString: String) -> (numericPart: String?, nonNumericPart: String?) {
        do {
            let regex = try NSRegularExpression(pattern: "([0-9]+\\.?[0-9]*)([^0-9]*)", options: .caseInsensitive)
            let range = NSRange(location: 0, length: formattedString.utf16.count)
            if let match = regex.firstMatch(in: formattedString, options: [], range: range) {
                let numericPart = (formattedString as NSString).substring(with: match.range(at: 1))
                let nonNumericPart = (formattedString as NSString).substring(with: match.range(at: 2))
                return (numericPart, nonNumericPart)
            }
        } catch {
            print("Error creating regular expression: \(error.localizedDescription)")
            logError(error: error as NSError, VCName: "PHAsset", functionName: #function, line: #line)
        }
        return (nil, nil)
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
    
    func makeCornerRadiusCircle(){
        layer.cornerRadius = bounds.height / 2
    }
    
    func makeCornerRadiusFourthOfHeightOrWidth(){
        layer.cornerRadius = bounds.width < bounds.height ? bounds.width / 4 : bounds.height / 4
    }
    
    func makeCornerRadiusEightOfHeightOrWidth(){
        layer.cornerRadius = bounds.width < bounds.height ? bounds.width / 8 : bounds.height / 8
    }
    
    func makeCornerRadiusSixtenthOfHeightOrWidth(){
//        layer.masksToBounds = true
        layer.cornerRadius = bounds.width < bounds.height ? bounds.width / 16 : bounds.height / 16
    }
    
    
    
    
    
    
    func activityStartAnimating(activityColor: UIColor = .gray, backgroundColor: UIColor = .clear, style: UIActivityIndicatorView.Style = .medium) {
        if viewWithTag(475647) != nil{ return }
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
    
    static var videoCompress: UIStoryboard{
        UIStoryboard(name: "VideoCompress", bundle: nil)
    }

    static var setting: UIStoryboard {
        UIStoryboard(name: "Setting", bundle: nil)
    }

    static var secretSpace: UIStoryboard{
        UIStoryboard(name: "SecretSpace", bundle: nil)
    }

    static var home: UIStoryboard {
        UIStoryboard(name: "Home", bundle: nil)
    }

    static var contact: UIStoryboard {
        UIStoryboard(name: "Contact", bundle: nil)
    }

    static var calendar: UIStoryboard {
        UIStoryboard(name: "Calendar", bundle: nil)
    }

    static var media: UIStoryboard {
        UIStoryboard(name: "Media", bundle: nil)
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
        let mainItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(1/2)))
        mainItem.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        
        
        // second style
        let horizontalPairItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/2), heightDimension: .fractionalHeight(1)))
        horizontalPairItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 2, bottom: 2, trailing: 2)
        
        let horizontalPairGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(1)), subitems: [horizontalPairItem, horizontalPairItem])
//        horizontalPairGroup.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)

        
        let nestedGroup = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(3/2)), subitems: [horizontalPairGroup, mainItem])
        nestedGroup.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
        let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        headerItem.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 6, bottom: 0, trailing: 6)
        
        
        let section = NSCollectionLayoutSection(group: nestedGroup)
        section.boundarySupplementaryItems = [headerItem]
        let layout = UICollectionViewCompositionalLayout(section: section)
        self.collectionViewLayout = layout
    }
}

private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            // Configure your sections, including the section for the header
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.boundarySupplementaryItems = [headerItem]

            return section
        }

        return layout
    }



extension Notification.Name{
        static let updateData = Notification.Name("UpdateDataNotification")
    
}




extension UIFont{
//
//    enum weightType: String {
//        case ultraLightItalic = "Ultra Light Italic"
//        case ultraLight = "Ultra Light"
//        case regular = "Regular"
//        case mediumItalic = "MediumItalic"
//        case medium = "Medium"
//        case italic = "Italic"
//        case heavyItalic = "Heavy Italic"
//        case heavy = "Heavy"
//        case demiBoldItalic = "Demi Bold Italic"
//        case demiBold = "Demi Bold"
//        case boldItalic = "Bold Italic"
//        case bold = "Bold"
//
//    }


    static func avenirNext(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont? {
            // Create a UIFontDescriptor with the given font name
            let baseDescriptor = UIFontDescriptor(name: "Avenir Next", size: size)

            // Create a new font descriptor with the added weight trait
            let fontDescriptor = baseDescriptor.addingAttributes([
                .traits: [UIFontDescriptor.TraitKey.weight: weight]
            ])

            // Return the custom font with the specified size and weight
            return UIFont(descriptor: fontDescriptor, size: size)
        }
}

extension UserDefaults{
    var appearanceMode: String{
        "appearanceMode"
    }
}




extension NSObject
{
    static var className: String{
        return String(describing : self)
    }
}
