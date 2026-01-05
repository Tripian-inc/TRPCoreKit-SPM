//
//  DynamicHeightCollectionView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 9.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

@objc(SPMDynamicHeightCollectionView)
class DynamicHeightCollectionView: UICollectionView {
    override func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
    }
    
    override func layoutSubviews() {

        super.layoutSubviews()

        if bounds.size != intrinsicContentSize {

        self.invalidateIntrinsicContentSize()

        }

    }

    override var intrinsicContentSize: CGSize {

        return collectionViewLayout.collectionViewContentSize

    }
    
    var didLayoutAction: (() -> Void)?
    
    func setCompositionalLayout(columnSize: CGFloat, insets: NSDirectionalEdgeInsets? = nil, cellHeight: CGFloat = 170, isItemInset: Bool = false) {
        var groupInsets = NSDirectionalEdgeInsets.zero
        var sectionInsets = NSDirectionalEdgeInsets.zero
        if insets != nil {
            groupInsets.bottom = insets!.bottom
            sectionInsets = insets!
        } else {
            groupInsets.bottom = 16
            sectionInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        }
        let fraction: CGFloat = 1 / columnSize
        
        // Item
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        if isItemInset {
            item.contentInsets = sectionInsets
        }
            
        // Group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(cellHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.contentInsets = groupInsets
        
        // Section
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = sectionInsets
        
        self.setCollectionViewLayout(UICollectionViewCompositionalLayout(section: section), animated: true)
        
    }
}
