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
import SwiftUI
//MARK: - PHAsset
extension PHAsset{
    
    //TODO: - Need action to make it Async/await compatible
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
    
    
    func getAVAsset() async -> AVAsset? {
        let manager = PHImageManager.default()
        let option = PHVideoRequestOptions()
//        option.isNetworkAccessAllowed = true
        option.deliveryMode = PHVideoRequestOptionsDeliveryMode.highQualityFormat
        
        let (avAsset, videoAudio) = await withCheckedContinuation { continuation in
            manager.requestAVAsset(forVideo: self, options: option) { avAsset, videoAudio, _ in
                if let avAsset{
                    continuation.resume(returning: (avAsset, videoAudio))
                }else{
                    logErrorString(errorString: "AVAsset not found", VCName: "PHAsset", functionName: #function, line: #line)
                }
            }
        }
        
        return avAsset
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

    
    func getImage() async -> UIImage? {
        let size = await CGSize(width: UIScreen.main.bounds.width/2, height: UIScreen.main.bounds.width/2)
         return await getImage(size: size)
    }
    
    
    private func getImage(size: CGSize) async -> UIImage? {
        let manager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        let size = size
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        
        let img = await withCheckedContinuation { continuation in
            manager.requestImage(for: self, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, _ in
                if image == nil{
                    logErrorString(errorString: "Can not get image from PHAsset by excaping", VCName: "PHAsset", functionName: #function, line: #line)
                }
                continuation.resume(returning: image)
            }
        }
        return img
    }
    
    
    func getThumbnail() async -> UIImage? {
        let size = await CGSize(width: UIScreen.main.bounds.width/4, height: UIScreen.main.bounds.width/4)
         return await getImage(size: size)
    }
 
    
    
    func getFullImage() async -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        let image = await withCheckedContinuation { continuation in
//            
            PHImageManager.default().requestImageDataAndOrientation(for: self, options: options) { data, s, _, _ in
                if let data {
                    let image = UIImage(data: data)
                    continuation.resume(returning: image)
                }
            }
        }
        
        return image
    }
}


//MARK: - UInt64

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
    
    func formatBytes() -> String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useAll]
        byteCountFormatter.countStyle = .file

        return byteCountFormatter.string(fromByteCount: Int64(self))
    }
}

//MARK: - Int64

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

//MARK: - Date
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

//MARK: - EKEvent

extension EKEvent{
    var year: String {
        startDate.toString(formatType: .yyyy)
    }
}

//MARK: - EKReminder
extension EKReminder{
    var year: String{
        (creationDate ?? Date()).toString(formatType: .yyyy)
    }
}


extension Notification.Name{
        static let updateData = Notification.Name("UpdateDataNotification")
    
}


//MARK: - UIFont

extension UIFont{


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
