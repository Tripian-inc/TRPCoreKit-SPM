//
//  ButterflyRestaurantHorizontalCollectionCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 1.05.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
class ButterflyRestaurantCell: ButterflyHorizontalCardCell {

    override func setupCustomView(stackView: UIStackView) {
        subLabel.numberOfLines = 1
    }
   
}
