//
//  ItineraryHotelCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 22.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

class ItineraryHotelCell: ItineraryBaseCell {
    
    
    public var alternativeHandler: ButtonClicked?
    
    override func addViewInCenterStack(_ stack: UIStackView) {
        
        addSubview(poiNameLabel)
        poiNameLabel.leadingAnchor.constraint(equalTo: poiImage.trailingAnchor, constant: 16).isActive = true
        poiNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -rightSpaceForEditing).isActive = true
        //poiNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
        poiNameLabel.centerYAnchor.constraint(equalTo: poiImage.centerYAnchor, constant: 0).isActive = true
    }
   
    
}
