//
//  CenteredTagsFlowLayout.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 28.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Centered tags flow layout for cuisines display
//

import UIKit

class CenteredTagsFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect)?.map({ $0.copy() as! UICollectionViewLayoutAttributes }) else {
            return nil
        }

        guard let collectionView = collectionView else { return attributes }

        let collectionViewWidth = collectionView.bounds.width - sectionInset.left - sectionInset.right

        var rows: [[UICollectionViewLayoutAttributes]] = []
        var currentRow: [UICollectionViewLayoutAttributes] = []
        var currentY: CGFloat = -1

        for attribute in attributes {
            if attribute.frame.origin.y != currentY {
                if !currentRow.isEmpty {
                    rows.append(currentRow)
                }
                currentRow = [attribute]
                currentY = attribute.frame.origin.y
            } else {
                currentRow.append(attribute)
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        for row in rows {
            let totalWidth = row.reduce(0) { $0 + $1.frame.width } + CGFloat(row.count - 1) * minimumInteritemSpacing
            let leadingOffset = (collectionViewWidth - totalWidth) / 2 + sectionInset.left

            var currentX = leadingOffset
            for attribute in row {
                attribute.frame.origin.x = currentX
                currentX += attribute.frame.width + minimumInteritemSpacing
            }
        }

        return attributes
    }
}
