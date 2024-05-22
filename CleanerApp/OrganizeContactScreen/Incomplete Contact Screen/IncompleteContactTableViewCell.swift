//
//  IncompleteContactTableViewCell.swift
//  CleanerApp
//
//  Created by Sneha Tyagi on 20/05/24.
//

import UIKit

protocol IncompleteContactTableViewCellDelegate{
    func incompleteContactTableViewCell( cell: IncompleteContactTableViewCell, checkButtonPressedAt index: Int)
}

class IncompleteContactTableViewCell: UITableViewCell {

    @IBOutlet weak var incompleteContactName: UILabel!
    
    @IBOutlet weak var checkMarkImageView: UIImageView!
    @IBOutlet weak var mainView: UIView!
    var index: Int!
    var delegate: IncompleteContactTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        mainView.layer.cornerRadius = 10
    }
    
    var isItemSelected: Bool = false{
        didSet{
            if isItemSelected{
                checkMarkImageView.image = UIImage(systemName: "checkmark.circle.fill",withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.white, .darkBlue]))
            }else{
                checkMarkImageView.image = UIImage(systemName: "circle" ,withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.darkGray3, .darkBlue]))
            }
            
        }
    }
    
    @IBAction func checkButtonPressed(_ sender: UIButton) {
        isItemSelected.toggle()
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
        delegate?.incompleteContactTableViewCell(cell: self, checkButtonPressedAt: index)

    
    }
    

 
    
}
