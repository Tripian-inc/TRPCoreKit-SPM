//
//  DescriptionCellController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 23.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

final class DescriptionCellController {
    private var cell: ExpandableTableViewCell?
    private var isExpand: Bool = false
    
    func configureCell(_ cell: ExpandableTableViewCell, model: String) {
        self.cell = cell
        self.cell!.descLabel.text = model
    }
    
    func didSelectCell() {
        if !isExpand {
            cell?.descLabel.numberOfLines = 0
        }else {
            cell?.descLabel.numberOfLines = 2
        }
        isExpand.toggle()
    }
}
