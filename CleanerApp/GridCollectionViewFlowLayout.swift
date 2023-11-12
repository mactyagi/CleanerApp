//
//  GridCollectionViewFlowLayout.swift
//  CleanerApp
//
//  Created by manu on 10/11/23.
//

import Foundation
import UIKit

class GridCollectionViewFlowLayout : UICollectionViewFlowLayout {
    private static let topLayoutMargin: CGFloat = 20
    private static let bottomLayoutMargin: CGFloat = 20
    private static let leftkLayoutMargin: CGFloat = 0
    private static let kSpacing: CGFloat = 22
    private static let kNumberOfColumn: CGFloat = 2
    private var columns: CGFloat = kNumberOfColumn
    private var cellHeight: CGFloat?
    private var spacing: CGFloat = kSpacing
    private var topLayoutMargin: CGFloat = topLayoutMargin
    private var bottomLayoutMargin: CGFloat = bottomLayoutMargin
    private var leftLayoutMargin: CGFloat = leftkLayoutMargin
    private var direction: UICollectionView.ScrollDirection = .vertical
    private var isLayoutForCell: Bool = false
    
    init(columns: CGFloat = kNumberOfColumn, cellheight: CGFloat? = nil, topLayoutMargin: CGFloat = topLayoutMargin, bottomLayoutMargin: CGFloat = bottomLayoutMargin, leftLayoutMargin: CGFloat = leftkLayoutMargin, spacing: CGFloat = kSpacing, direction: UICollectionView.ScrollDirection = .vertical, isLayoutForCell: Bool = false) {
        self.columns = columns
        self.cellHeight = cellheight
        self.direction = direction
        self.spacing = spacing
        self.topLayoutMargin = topLayoutMargin
        self.bottomLayoutMargin = bottomLayoutMargin
        self.leftLayoutMargin = leftLayoutMargin
        self.isLayoutForCell = isLayoutForCell
        super.init()
        commonInit()
    }
    
    override init() {
        super.init()
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        configLayout()
    }
    
    private func configLayout() {
        self.scrollDirection = direction
        minimumLineSpacing = spacing
        minimumInteritemSpacing = spacing
        sectionInset = UIEdgeInsets(top: topLayoutMargin, left: leftLayoutMargin, bottom: bottomLayoutMargin, right: leftLayoutMargin)
        if let collectionView = self.collectionView {
            var optimisedWidth = (collectionView.frame.width - minimumInteritemSpacing - 2 * leftLayoutMargin) / self.columns
            if isLayoutForCell {
                optimisedWidth = (UIScreen.main.bounds.width - minimumInteritemSpacing - 2 * leftLayoutMargin) / self.columns
            }
            if let cellHeight{
                self.itemSize = CGSize(width: optimisedWidth , height: cellHeight)
            }else{
                self.itemSize = CGSize(width: optimisedWidth , height: optimisedWidth) // keep as square
            }
             
        }
    }
    
    override func invalidateLayout() {
        super.invalidateLayout()
        self.configLayout()
    }

}

