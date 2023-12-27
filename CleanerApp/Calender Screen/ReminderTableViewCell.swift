//
//  ReminderTableViewCell.swift
//  CleanerApp
//
//  Created by Manu on 26/12/23.
//

import UIKit

class ReminderTableViewCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    static var identifier = "ReminderTableViewCell"
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureCell(reminder:CustomEKReminder){
        titleLabel.text = reminder.reminder.title
        dateLabel.text = (reminder.reminder.creationDate ?? Date()).toString(formatType: .ddmmmyyyy)
        if reminder.isSelected{
            let configuration = UIImage.SymbolConfiguration(paletteColors: [.white, .tintColor])
            myImageView.tintColor = .tintColor
            myImageView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: configuration)
        }else{
            myImageView.tintColor = .lightGrayAndDarkGray2
            myImageView.image = UIImage(systemName: "circle")
        }
    }
}
