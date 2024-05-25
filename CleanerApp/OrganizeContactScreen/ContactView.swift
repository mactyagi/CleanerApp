//
//  ContactView.swift
//  CleanerApp
//
//  Created by Manu on 20/02/24.
//

import UIKit
import Contacts

protocol ContactViewDelegate{
    func contactView(_ view: ContactView, isSelected: Bool) 
    func contactView(_ view: ContactView, didPressedContact contact: CNContact?)
}

extension ContactViewDelegate {

    func contactView(_ view: ContactView, didPressedContact contact: CNContact?) {

    }

    func contactView(_ view: ContactView, isSelected: Bool) {

    }
}

class ContactView: UIView {

    var delegate: ContactViewDelegate?
    var contact: CNContact?

    @IBOutlet weak var checkMarkImageView: UIImageView!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var NameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
//        NameLabel.isHidden = true
//        phoneNumberLabel.isHidden = true
    }

    var isSelected = true{
        didSet{
            if isSelected{
                checkMarkImageView.image = UIImage(systemName: "checkmark.circle.fill",withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.white, .darkBlue]))
            }else{
                checkMarkImageView.image = UIImage(systemName: "circle" ,withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.darkGray3, .darkBlue]))
            }
            
        }
    }

    func configureContactView(contact:CNContact) {
        self.contact = contact
        let name = "\(contact.givenName) \(contact.familyName)"
        let phoneNumber = "\(contact.phoneNumbers.compactMap { $0.value.stringValue }.joined(separator: " • "))"
        NameLabel.text = name
        NameLabel.isHidden = name == " "

        phoneNumberLabel.text = phoneNumber
        phoneNumberLabel.isHidden = phoneNumber.isEmpty

    }

    override init(frame: CGRect) {
            super.init(frame: frame)
            setupView()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            setupView()
        }
    
    @IBAction func checkButtonPressed(_ sender: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
        isSelected.toggle()
        delegate?.contactView(self, isSelected: isSelected)
    }
    
    @IBAction func contactSelectButtonPressed(_ sender: UIButton) {
        delegate?.contactView(self, didPressedContact: contact)
    }
    
        
    private func setupView() {
            self.layer.cornerRadius = 20
            Bundle.main.loadNibNamed("ContactView", owner: self)
            addSubview(contentView)
            contentView.frame = self.bounds
            contentView.layer.cornerRadius = 20
            contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//            NameLabel.isHidden = true
//            phoneNumberLabel.isHidden = true
        }

    
}
