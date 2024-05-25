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
    func duplicateContactTableViewCell(_ cell: DuplicateContactTableViewCell, didContactSelected contact: CNContact?)
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
        duplicateCount.text = "Duplicate Count: \(duplicateContacts.count)"
        stackView.arrangedSubviews.forEach { stackView.removeArrangedSubview($0)}
        isAllselected = true
        shouldEnableMergeButton = duplicateContacts.filter({ $0.isSelected}).count > 1
        for (index,duplicateContact) in duplicateContacts.enumerated() {
            let view = ContactView()
            view.delegate = self
            view.tag = index
            view.isSelected = duplicateContact.isSelected
            if duplicateContact.isSelected == false{
                isAllselected = false
            }
            view.configureContactView(contact: duplicateContact.contact)

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
        mergedContactView.delegate = self
        mergedContactView.configureContactView(contact: mergedContact)
    }
}


extension DuplicateContactTableViewCell: ContactViewDelegate{

    func contactView(_ view: ContactView, isSelected: Bool) {
        delegate?.duplicateContactTableViewCell(self, didChangeAt: indexPath, viewIndex: view.tag, isSelected: view.isSelected)
    }
    

    func contactView(_ view: ContactView, didPressedContact contact: CNContact?) {
        delegate?.duplicateContactTableViewCell(self, didContactSelected: contact)
    }
}
