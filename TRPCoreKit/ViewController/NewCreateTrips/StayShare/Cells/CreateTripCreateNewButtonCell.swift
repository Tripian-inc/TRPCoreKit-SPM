//
//  CreateTripCreateNewButtonCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 6.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

class CreateTripCreateNewButtonCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!
    
    public var action: (() -> Void)?
    
    public func setupCell(text: String) {
        label.textColor = trpTheme.color.tripianBlack
        label.font = trpTheme.font.header2
        label.text = text
        
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
        button.backgroundColor = .clear
        button.layer.cornerRadius = 10
    }
    
    @IBAction func createPressed(_ sender: Any) {
        self.action?()
    }
    
}
