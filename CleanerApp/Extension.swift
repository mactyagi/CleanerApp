//
//  Extension.swift
//  CleanerApp
//
//  Created by manu on 08/11/23.
//

import Foundation
import Photos
import UIKit
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
}



extension UIViewController{
    static var className : String{
        return String(describing: type(of: self))
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
}



