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
    
    
    static let batteryCell = HomeCell(image: UIImage(systemName: "battery.100.bolt") ?? UIImage(), title: "Battery", subtitle: "Liven up your charging screen", imageBackgroundColor: .systemGreen)
    static let speedTest = HomeCell(image: UIImage(systemName: "battery.100.bolt") ?? UIImage(), title: "Speed Test", subtitle: "Check Your Internet Speed", imageBackgroundColor: .systemGreen)
    static let batteryCell = HomeCell(image: UIImage(systemName: "battery.100.bolt") ?? UIImage(), title: "Widgets", subtitle: "Add widgets to home screen", imageBackgroundColor: .systemGreen)
    static let batteryCell = HomeCell(image: UIImage(systemName: "battery.100.bolt") ?? UIImage(), title: "Video Compressor", subtitle: "Reduce video size", imageBackgroundColor: .systemGreen)
    static let batteryCell = HomeCell(image: UIImage(systemName: "battery.100.bolt") ?? UIImage(), title: "Secret Space", subtitle: "Hide your private files", imageBackgroundColor: .systemGreen)
    static let batteryCell = HomeCell(image: UIImage(systemName: "battery.100.bolt") ?? UIImage(), title: "Battery", subtitle: "Liven up your charging screen", imageBackgroundColor: .systemGreen)
}


enum HomeCellType{
    case battery
    
    var cell: HomeCell{
        switch self {
        case .battery:
            HomeCell.batteryCell
        }
    }
}
