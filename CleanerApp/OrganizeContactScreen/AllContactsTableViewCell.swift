//
//  AllContactsTableViewCell.swift
//  CleanerApp
//
//  Created by Manukant Tyagi on 25/05/24.
//

import UIKit
import Contacts


class AllContactsTableViewCell: UITableViewCell {

    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var selectionView: UIView!
    @IBOutlet weak var selectionImageView: UIImageView!


    override func awakeFromNib() {
        super.awakeFromNib()
        contactImageView.layer.cornerRadius = contactImageView.bounds.height / 2
        contactImageView.clipsToBounds = true
        contactImageView.layer.masksToBounds = true
    }

    var isContactSelected: Bool = false {
        didSet {
            if isContactSelected{
                selectionImageView.image = UIImage(systemName: "checkmark.circle.fill",withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.white, .darkBlue]))
            }else{
                selectionImageView.image = UIImage(systemName: "circle" ,withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.darkGray3, .darkBlue]))
            }
        }
    }

    func configureContact(contact: CNContact, isSelected: Bool?) {
        if let isSelected {
            selectionView.isHidden = false
            isContactSelected = isSelected
        }else {
            selectionView.isHidden = true
        }
        let name = "\(contact.givenName) \(contact.familyName)"
        let phoneNumber = "\(contact.phoneNumbers.compactMap { $0.value.stringValue }.joined(separator: " • "))"
        titleLabel.text = name
        subtitleLabel.isHidden = true

        if name == " " {
            titleLabel.text = phoneNumber
        }
        contactImageView.image = getImageForContact(contact)
    }

    func getImageForContact(_ contact: CNContact) -> UIImage? {
        if let imageData = contact.imageData {
            return UIImage(data: imageData)
        } else {
            // If image is not available, create a circular image with the first capital letter of the contact's name
            let initials = String(contact.givenName.first ?? " ") + String(contact.familyName.first ?? " ")
            return imageWithInitials(initials)
        }
    }

    func imageWithInitials(_ initials: String) -> UIImage? {
        let frame = CGRect(x: 0, y: 0, width: 100, height: 100) // Adjust size as needed
        let imageView = UIImageView(frame: frame)
        imageView.backgroundColor = UIColor.darkGray3 // Background color of the circular image
        imageView.layer.cornerRadius = frame.width / 2 // Make it circular
        imageView.clipsToBounds = true
        imageView.contentMode = .center

        let label = UILabel(frame: frame)
        label.text = initials
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 40) // Adjust font size as needed
        label.textAlignment = .center
        imageView.addSubview(label)

        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }

}
