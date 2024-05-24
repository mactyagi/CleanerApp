//
//  ContactView.swift
//  CleanerApp
//
//  Created by Manu on 20/02/24.
//

import UIKit
import Contacts

protocol ContactViewDelegate{
    func contactView(_ view: ContactView, didPressedCheckButtonAt index: Int)
    func contactView(_ view: ContactView, didPressedContact contact: CNContact?)
}

extension ContactViewDelegate {

    func contactView(_ view: ContactView, didPressedContact contact: CNContact?) {

    }

    func contactView(_ view: ContactView, didPressedCheckButtonAt index: Int) {

    }
}

class ContactView: UIView {

    var delegate: ContactViewDelegate?
    var index: Int = 0
    var contact: CNContact?

    @IBOutlet weak var checkMarkImageView: UIImageView!
    @IBOutlet weak var phoneNumberLabel: UILabel!{
        didSet{
            phoneNumberLabel.isHidden = (phoneNumberLabel.text?.isEmpty ?? true)
        }
    }
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var NameLabel: UILabel!{
        didSet{
            NameLabel.isHidden = (NameLabel.text?.isEmpty ?? true)
        }
    }

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
        if name == " "{
            NameLabel.text = ""
        }else{
           NameLabel.text = name
        }
        phoneNumberLabel.text = phoneNumber
        
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
        delegate?.contactView(self, didPressedCheckButtonAt: index)
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
