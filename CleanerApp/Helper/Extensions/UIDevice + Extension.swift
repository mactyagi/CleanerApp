//
//  UIDevice + Extension.swift
//  CleanerApp
//
//  Created by Manukant Harshmani Tyagi on 08/08/25.
//

import Foundation
import UIKit

extension UIDevice {
    static var deviceId: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
}
