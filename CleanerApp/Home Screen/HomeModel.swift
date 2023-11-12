//
//  HomeCell.swift
//  CleanerApp
//
//  Created by manu on 06/11/23.
//

import Foundation
import UIKit
struct HomeCell{
    var image: UIImage
    var title: String
    var subtitle: String
    var imageBackgroundColor: UIColor
    var cellType: HomeCellType
    
    
    static let batteryCell = HomeCell(image: UIImage(systemName: "battery.100.bolt") ?? UIImage(), title: "Battery", subtitle: "Liven up your charging screen", imageBackgroundColor: .systemGreen, cellType: .battery)
    static let speedTestCell = HomeCell(image: UIImage(systemName: "speedometer") ?? UIImage(), title: "Speed Test", subtitle: "Check Your Internet Speed", imageBackgroundColor: .systemOrange, cellType: .speedTest)
    static let widgetCell = HomeCell(image: UIImage(systemName: "tray.fill") ?? UIImage(), title: "Widgets", subtitle: "Add widgets to home screen", imageBackgroundColor: .systemTeal, cellType: .widgetCell)
    static let videoCompressorCell = HomeCell(image: UIImage(systemName: "video.fill") ?? UIImage(), title: "Video Compressor", subtitle: "Reduce video size", imageBackgroundColor: .systemPurple, cellType: .videoCompressor)
    static let secretSpaceCell = HomeCell(image: UIImage(systemName: "lock.open.fill") ?? UIImage(), title: "Secret Space", subtitle: "Hide your private files", imageBackgroundColor: .systemIndigo, cellType: .secretSpace)
}


enum HomeCellType{
    case battery
    case speedTest
    case widgetCell
    case videoCompressor
    case secretSpace
    
    var cell: HomeCell{
        switch self {
        case .battery:
            HomeCell.batteryCell
        case .speedTest:
            HomeCell.speedTestCell
        case .widgetCell:
            HomeCell.widgetCell
        case .videoCompressor:
            HomeCell.videoCompressorCell
        case .secretSpace:
            HomeCell.secretSpaceCell
        }
    }
}
