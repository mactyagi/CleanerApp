//
//  ContactView.swift
//  CleanerApp
//
//  Created by Manu on 20/02/24.
//

import UIKit

protocol ContactViewDelegate{
    func contactView(_ view: ContactView, didPressedCheckButtonAt index: Int)
}

class ContactView: UIView {

    var delegate: ContactViewDelegate?
    var index: Int = 0
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
    var isSelected = true{
        didSet{
            if isSelected{
                checkMarkImageView.image = UIImage(systemName: "checkmark.circle.fill",withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.white, .darkBlue]))
            }else{
                checkMarkImageView.image = UIImage(systemName: "circle" ,withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.darkGray3, .darkBlue]))
            }
            
        }
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
        isSelected.toggle()
        delegate?.contactView(self, didPressedCheckButtonAt: index)
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
