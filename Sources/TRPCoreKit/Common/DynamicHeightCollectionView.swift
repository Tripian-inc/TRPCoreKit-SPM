//
//  DynamicHeightCollectionView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 9.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

class DynamicHeightCollectionView: UICollectionView {
//    override var intrinsicContentSize: CGSize {
//        self.layoutIfNeeded()
//        return self.contentSize
//    }

//    override var contentSize: CGSize {
//        didSet{
//            self.invalidateIntrinsicContentSize()
//        }
//    }

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
}
