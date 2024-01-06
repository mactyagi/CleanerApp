//
//  MediaCollectionViewCell.swift
//  CleanerApp
//
//  Created by Manu on 06/01/24.
//

import UIKit

class MediaCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    
    static let identifier = "MediaCollectionViewCell"
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    
    func configure(cellType: MediaCellType) {
        titleLabel.text = cellType.cell.mainTitle
        stackView.axis = cellType.cell.stackShouldVertical ? .vertical : .horizontal
        if cellType.cell.asset.isEmpty{
            let imageView = UIImageView()
            imageView.image = UIImage(named: cellType.cell.imageName)
            stackView.addArrangedSubview(imageView)
        }
        for asset in cellType.cell.asset{
            let imageView = UIImageView()
            imageView.image = asset.getImage()
            stackView.addArrangedSubview(imageView)
            
        }
    }

}
