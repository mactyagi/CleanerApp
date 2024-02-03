//
//  MediaCollectionViewCell.swift
//  CleanerApp
//
//  Created by Manu on 06/01/24.
//

import UIKit

class MediaCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView5: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    
    static let identifier = "MediaCollectionViewCell"
    override func awakeFromNib() {
        super.awakeFromNib()
        mainView.makeCornerRadiusSixtenthOfHeightOrWidth()
        descriptionView.makeCornerRadiusFourthOfHeightOrWidth()
        setupImageView(imageView1, imageView2, imageView3, imageView4, imageView5, isHidden: true)
        
    }
    
    
    func setupImageView(_ imageViews: UIImageView..., isHidden: Bool){
        imageViews.forEach { view in
            view.isHidden = isHidden
            view.makeCornerRadiusSixtenthOfHeightOrWidth()
        }
    }
    
    func configureCell(_ cell: MediaCell) {
        setupImageView(imageView1, imageView2, imageView3, imageView4, imageView5, isHidden: true)
        imageView1.image = UIImage(systemName: cell.imageName)
        imageView1.isHidden = false
        imageView1.contentMode = .scaleAspectFit
        
        for (index, asset) in cell.asset.enumerated() {
            switch index{
            case 0:
                imageView1.image = asset.getImage()
                imageView1.isHidden = false
                imageView1.contentMode = .scaleAspectFill
            case 1:
                imageView2.image = asset.getImage()
                imageView2.isHidden = false
            case 2:
                imageView3.image = asset.getImage()
                imageView3.isHidden = false
            case 3:
                imageView4.image = asset.getImage()
                imageView4.isHidden = false
            case 4:
                imageView5.image = asset.getImage()
                imageView5.isHidden = false
            default:
                break
            }
        }
        
        
        
        titleLabel.text = cell.mainTitle
        stackView.axis = cell.stackShouldVertical ? .vertical : .horizontal
        sizeLabel.text = cell.size.formatBytes()
        countLabel.text = "\(cell.count) Photos"
    }

}
