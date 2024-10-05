//
//  DateAndTravellerNumberOfPeopleCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 22.06.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
class DateAndTravellerNumberOfPeopleCell: UITableViewCell {
    @IBOutlet weak var inputText: TRPTextField!
    
    
    public func setupUI(){
        let leftImage = TRPImageController().getImage(inFramework: "icon_travelers", inApp: nil) ?? UIImage()
        inputText.setLeftImage(image: leftImage)
    }
    
}
