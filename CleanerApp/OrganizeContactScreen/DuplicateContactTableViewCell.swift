//
//  DuplicateContactTableViewCell.swift
//  CleanerApp
//
//  Created by Manu on 20/02/24.
//

import UIKit
import Contacts

protocol DuplicateContactTableViewCellDelegate{
    func duplicateContactTableViewCell(_ cell: UITableViewCell, didChangeAt indexPath: IndexPath, viewIndex: Int, isSelected: Bool)
    func duplicateContactTableViewCell(_ cell: UITableViewCell, selectionAt indexPath: IndexPath, isAllSelected: Bool)
    func duplicateContactTableViewCell(_ cell: UITableViewCell, mergeContactAt indexPath: IndexPath)
}
class DuplicateContactTableViewCell: UITableViewCell{
   
    
    @IBOutlet weak var mergeContactButton: UIButton!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var duplicateCount: UILabel!
    @IBOutlet weak var mergedContactView: ContactView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    
    var delegate: DuplicateContactTableViewCellDelegate?
    var tuple: duplicateAndMergedContactTuple!
    var shouldEnableMergeButton = false{
        didSet{
            mergeContactButton.isEnabled = shouldEnableMergeButton
        }
    }
    
    var isAllselected = false{
        didSet{
            selectButton.setTitle( isAllselected ? "Deselect All" : "Select All", for: .normal)
        }
    }
    var indexPath: IndexPath!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupViews()
    }
    
    @IBAction func selectButtonPressed(_ sender: UIButton) {
        isAllselected.toggle()
        delegate?.duplicateContactTableViewCell(self, selectionAt: indexPath, isAllSelected: isAllselected)
    }
    
    @IBAction func mergeContactButtonPressed(_ sender: UIButton) {
        delegate?.duplicateContactTableViewCell(self, mergeContactAt: indexPath)
    }
    func configure(tuple: duplicateAndMergedContactTuple, indexPath: IndexPath){
        self.indexPath = indexPath
        setupStackView(duplicateContacts: tuple.duplicatesContacts)
        setMergedContact(mergedContact: tuple.mergedContact)
    }
    
    func setupViews(){
        mainView.layer.cornerRadius = 20
        mergedContactView.backgroundColor = .lightBlueDarkGrey
        mergedContactView.contentView.backgroundColor = .lightBlueDarkGrey
        mergedContactView.checkMarkImageView.superview?.isHidden = true
        mergeContactButton.isEnabled = false
    }
    
    func setupStackView(duplicateContacts: [CustomCNContact]){
        stackView.arrangedSubviews.forEach { stackView.removeArrangedSubview($0)}
        isAllselected = true
        shouldEnableMergeButton = duplicateContacts.filter({ $0.isSelected}).count > 1
        for (index,duplicateContact) in duplicateContacts.enumerated() {
            let view = ContactView()
            view.delegate = self
            view.index = index
            view.isSelected = duplicateContact.isSelected
            if duplicateContact.isSelected == false{
                isAllselected = false
            }
            let name = "\(duplicateContact.contact.givenName) \(duplicateContact.contact.familyName)"
            let phoneNumber = "\(duplicateContact.contact.phoneNumbers.compactMap { $0.value.stringValue }.joined(separator: " • "))"
            if name == " "{
                view.NameLabel.text = ""
            }else{
                view.NameLabel.text = name
            }
            
            view.phoneNumberLabel.text = phoneNumber
            
            stackView.addArrangedSubview(view)
            
            view.heightAnchor.constraint(equalToConstant: 70).isActive = true
            view.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        }
    }
    
    func setMergedContact(mergedContact: CNMutableContact?){
        guard let mergedContact else {
            mergedContactView.isHidden = true
            return
        }
        mergedContactView.isHidden = false
        mergedContactView.NameLabel.text = "\(mergedContact.givenName) \(mergedContact.familyName )"
        mergedContactView.phoneNumberLabel.text = mergedContact.phoneNumbers.compactMap { $0.value.stringValue }.joined(separator: " • ")
    }
}


extension DuplicateContactTableViewCell: ContactViewDelegate{
    func contactView(_ view: ContactView, didPressedCheckButtonAt index: Int) {
        delegate?.duplicateContactTableViewCell(self, didChangeAt: indexPath, viewIndex: index, isSelected: view.isSelected)
    }
    
    
}
