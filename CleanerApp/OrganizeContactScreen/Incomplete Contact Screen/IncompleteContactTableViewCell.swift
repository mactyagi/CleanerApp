//
//  IncompleteContactTableViewCell.swift
//  CleanerApp
//
//  Created by Sneha Tyagi on 20/05/24.
//

import UIKit
import Contacts

protocol IncompleteContactTableViewCellDelegate{
    func incompleteContactTableViewCell( cell: IncompleteContactTableViewCell, checkButtonPressedAt index: Int)
    func incompleteContactTableViewCell(cell: IncompleteContactTableViewCell, didSelectContact contact: CNContact?)
}

class IncompleteContactTableViewCell: UITableViewCell {

    @IBOutlet weak var contactView: ContactView!
    var delegate: IncompleteContactTableViewCellDelegate?
    var index: Int!
    override func awakeFromNib() {
        super.awakeFromNib()
        contactView.delegate = self
        contactView.phoneNumberLabel.textColor = .label
    }
    
    var isItemSelected: Bool = false{
        didSet{
            contactView.isSelected = isItemSelected
        }
    }
}

extension IncompleteContactTableViewCell: ContactViewDelegate{
    func contactView(_ view: ContactView, isSelected: Bool) {
        delegate?.incompleteContactTableViewCell(cell: self, checkButtonPressedAt: index)
    }

    func contactView(_ view: ContactView, didPressedContact contact: CNContact?) {
        delegate?.incompleteContactTableViewCell(cell: self, didSelectContact: contact)
    }
}
