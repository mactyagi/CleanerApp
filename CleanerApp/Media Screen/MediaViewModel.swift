//
//  MediaViewModel.swift
//  CleanerApp
//
//  Created by Manu on 06/01/24.
//

import Foundation

class MediaViewModel{
    
    var sections: [(title:String, cells: [MediaCellType])] = [
        ("Photo", [.duplicatePhoto, .similarPhoto, .otherPhoto]),
        ("Screenshot", [.duplicateScreenshot, .similarScreenshot, .otherScreenshot])
    ]
    
    
    
    
}
