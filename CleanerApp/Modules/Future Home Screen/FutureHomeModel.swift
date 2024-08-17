//
//  HomeCell.swift
//  CleanerApp
//
//  Created by manu on 06/11/23.
//

import Foundation
import UIKit
struct FutureHomeCell{
    var image: UIImage
    var title: String
    var subtitle: String
    var imageBackgroundColor: UIColor
    var cellType: FutureHomeCellType
    
    
    static let batteryCell = FutureHomeCell(image: UIImage(systemName: "battery.100.bolt") ?? UIImage(), title: "Battery", subtitle: "Liven up your charging screen", imageBackgroundColor: .systemGreen, cellType: .battery)
    static let speedTestCell = FutureHomeCell(image: UIImage(systemName: "speedometer") ?? UIImage(), title: "Speed Test", subtitle: "Check Your Internet Speed", imageBackgroundColor: .systemOrange, cellType: .speedTest)
    static let widgetCell = FutureHomeCell(image: UIImage(systemName: "tray.fill") ?? UIImage(), title: "Widgets", subtitle: "Add widgets to home screen", imageBackgroundColor: .systemTeal, cellType: .widgetCell)
    static let videoCompressorCell = FutureHomeCell(image: UIImage(systemName: "video.fill") ?? UIImage(), title: "Video Compressor", subtitle: "Reduce video size", imageBackgroundColor: .systemPurple, cellType: .videoCompressor)
    static let secretSpaceCell = FutureHomeCell(image: UIImage(systemName: "lock.open.fill") ?? UIImage(), title: "Secret Space", subtitle: "Hide your private files", imageBackgroundColor: .systemIndigo, cellType: .secretSpace)
}


enum FutureHomeCellType{
    case battery
    case speedTest
    case widgetCell
    case videoCompressor
    case secretSpace
    
    var cell: FutureHomeCell{
        switch self {
        case .battery:
            FutureHomeCell.batteryCell
        case .speedTest:
            FutureHomeCell.speedTestCell
        case .widgetCell:
            FutureHomeCell.widgetCell
        case .videoCompressor:
            FutureHomeCell.videoCompressorCell
        case .secretSpace:
            FutureHomeCell.secretSpaceCell
        }
    }
}
