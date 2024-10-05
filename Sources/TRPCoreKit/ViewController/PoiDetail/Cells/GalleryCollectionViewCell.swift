//
//  GalleryCollectionViewCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 28.07.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import TRPUIKit

class GalleryCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func setImage(_ item: PagingImage?){
        guard let item = item else {return}
        guard let imageUrl = item.imageUrl else {return}
        if let url = URL(string: imageUrl){
            imageView.sd_setImage(with: url, placeholderImage: nil)
        }
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: 0)
        layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        return layoutAttributes
    }
}
