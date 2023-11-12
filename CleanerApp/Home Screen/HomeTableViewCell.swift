//
//  HomeTableViewCell.swift
//  CleanerApp
//
//  Created by manu on 06/11/23.
//

import UIKit

class HomeTableViewCell: UITableViewCell {

    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var mainTitleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var imageBackgroundView: UIView!
    static let identifier = "HomeTableViewCell"
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    private func setupView(){

        }
    
    func configureCell(homeCell: HomeCell){
        subTitleLabel.text = homeCell.subtitle
        mainTitleLabel.text = homeCell.title
        iconImageView.image = homeCell.image
        imageBackgroundView.backgroundColor = homeCell.imageBackgroundColor
    }
}

extension UITableViewCell {
    func addCustomDisclosureIndicator(with color: UIColor) {
        accessoryType = .disclosureIndicator
        let disclosureImage = UIImage(named: "rightArrow")?.withRenderingMode(.alwaysTemplate)
        let imageWidth = 7
        let imageHeight = 12
        let accessoryImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        accessoryImageView.contentMode = .scaleAspectFit
        accessoryImageView.image = disclosureImage
        accessoryImageView.tintColor = color
        accessoryView = accessoryImageView
    }
}
