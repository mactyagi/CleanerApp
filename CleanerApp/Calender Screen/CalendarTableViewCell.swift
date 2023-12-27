//
//  CalendarTableViewCell.swift
//  CleanerApp
//
//  Created by Manu on 24/12/23.
//

import UIKit

class CalendarTableViewCell: UITableViewCell {

    @IBOutlet weak var checkmarkImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var leftSubtitleLabel: UILabel!
    
    static var identifier = "CalendarTableViewCell"
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureCell(event: CustomEKEvent){
        titleLabel.text = event.event.title
        dateLabel.text = event.event.startDate.toString(formatType: .ddmmmyyyy)
        leftSubtitleLabel.text = "Calendar: \(event.event.calendar.title )"
        if event.isSelected{
            let configuration = UIImage.SymbolConfiguration(paletteColors: [.white, .tintColor])
            checkmarkImageView.tintColor = .tintColor
            checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: configuration)
        }else{
            checkmarkImageView.tintColor = .lightGrayAndDarkGray2
            checkmarkImageView.image = UIImage(systemName: "circle")
        }
    }


}
