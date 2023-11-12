//
//  CollectionViewCell.swift
//  CleanerApp
//
//  Created by manu on 09/11/23.
//

import UIKit

class CompressCollectionViewCell: UICollectionViewCell {

    //MARK: - IBOutlet
    @IBOutlet weak var afterSizeLabel: UILabel!
    @IBOutlet weak var nowSizeLabel: UILabel!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var mainView: UIView!
    
    //MARK: - variables
    static let identifier = "CompressCollectionViewCell"
    
    //MARK: - LifeCycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
    }
    
    
    //MARK: - function
    
    func setupViews(){
        mainView.layer.cornerRadius = 20
        bottomView.layer.cornerRadius = 20
        cellImageView.layer.cornerRadius = 16
        cellImageView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }
    
    
    func configureCell(compressAsset: CompressVideoModel){
        compressAsset.phAsset.getImage(comp: { image in
            self.cellImageView.image = image
        })
        nowSizeLabel.text = compressAsset.originalSize.convertToFileString()
        
        
    }
    
}
