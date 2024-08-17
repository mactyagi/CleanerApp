//
//  MediaHeaderView.swift
//  CleanerApp
//
//  Created by Manu on 28/01/24.
//

import UIKit

class MediaHeaderView: UICollectionReusableView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var mainView: UIView!
    static let identifier = "MediaHeaderView"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mainView.makeCornerRadiusFourthOfHeightOrWidth()
        // Initialization code
    }
    
}
