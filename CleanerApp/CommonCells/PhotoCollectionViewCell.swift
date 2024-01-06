//
//  PhotoCollectionViewCell.swift
//  CleanerApp
//
//  Created by Manu on 05/01/24.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var checkUnCheckImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 16
    }
    
    
    static let identifier = "PhotoCollectionViewCell"
    
    
    
    func configureNewCell(asset: CustomAsset){
        myImageView.layer.cornerRadius = 16
        if let phAsset = asset.getPHAsset(){
            phAsset.getImage { image in
                self.myImageView.image = image
            }
        }
    }
}
