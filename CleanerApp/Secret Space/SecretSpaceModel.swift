//
//  SecretSpaceModel.swift
//  CleanerApp
//
//  Created by manu on 15/11/23.
//

import Foundation
import UIKit

struct SecretSpaceModel{
    var title: String
    var subtitle: String
    var image: UIImage
    var imageBackgroundColor: UIColor
    var cellType: SecretSpaceCellType
}

enum SecretSpaceCellType{
    case SecretAlbum
    case SecretContacts
    case SetPasscode
    
    var cell : SecretSpaceModel{
        switch self {
        case .SecretAlbum:
            SecretSpaceModel(title: "Secret Album", subtitle: "Your private Photos and videos", image: UIImage(systemName: "photo.stack.fill")!, imageBackgroundColor: UIColor.systemTeal , cellType: .SecretAlbum)
        case .SecretContacts:
            SecretSpaceModel(title: "Secret Contacts", subtitle: "Your private Contacts", image: UIImage(systemName: "person.crop.circle.fill")!, imageBackgroundColor: UIColor.systemYellow , cellType: .SecretContacts)
        case .SetPasscode:
            SecretSpaceModel(title: "Set Passcode", subtitle: "Enhance storage security", image: UIImage(systemName: "lock.shield.fill")!, imageBackgroundColor: UIColor.systemRed , cellType: .SetPasscode)
        }
    }
}
