//
//  BaseHeaderCollectionReusableView.swift
//  CleanerApp
//
//  Created by Manu on 17/01/24.
//

import UIKit

protocol BaseHeaderCollectionReusableViewDelegate{
    func baseHeaderCollectionReusableView(_ reusableView: BaseHeaderCollectionReusableView, didSelectButtonPressedAt section: Int)
}

class BaseHeaderCollectionReusableView: UICollectionReusableView {

    
    @IBOutlet weak var selectionButton: UIButton!
    @IBOutlet weak var countLabel: UILabel!
    var isAllSelected = true{
        didSet{
            selectionButton.setTitle(isAllSelected ? ConstantString.deSelectAll.rawValue : ConstantString.selectAll.rawValue, for: .normal)
        }
    }
    var delegate: BaseHeaderCollectionReusableViewDelegate?
    var section: Int!
    
    static let identifier = "BaseHeaderCollectionReusableView"
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func selectionButtonPressed(_ sender: UIButton) {
        isAllSelected.toggle()
        delegate?.baseHeaderCollectionReusableView(self, didSelectButtonPressedAt: section)
    }
    
}
