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
    var index: Int!
    var delegate: IncompleteContactTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contactView.delegate = self
        // Initialization code
//        mainView.layer.cornerRadius = 10
    }
    
    var isItemSelected: Bool = false{
        didSet{
            contactView.isSelected = isItemSelected
        }
    }
}

extension IncompleteContactTableViewCell: ContactViewDelegate{
    func contactView(_ view: ContactView, didPressedCheckButtonAt index: Int) {
        delegate?.incompleteContactTableViewCell(cell: self, checkButtonPressedAt: index)
    }

    func contactView(_ view: ContactView, didPressedContact contact: CNContact?) {
        delegate?.incompleteContactTableViewCell(cell: self, didSelectContact: contact)
    }
}
