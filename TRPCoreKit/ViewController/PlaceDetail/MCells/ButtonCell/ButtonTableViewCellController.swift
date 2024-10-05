//
//  ButtonTableViewCellController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 13.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
protocol ButtonTableViewCellControllerDelegate: AnyObject {
    func buttonTableViewCellButtonPressed(_ sender: UIButton)
}

final class ButtonTableViewCellController: GenericCellController<ButtonTableViewCell> {
    private let item: ButtonCellModel
    private var cell: ButtonTableViewCell?
    
    var cellheight:CGFloat = 80
    weak var delegate: ButtonTableViewCellControllerDelegate?
    
    
    init(cellModel: ButtonCellModel) {
        self.item = cellModel
    }
    
    override func configureCell(_ cell: ButtonTableViewCell) {
        self.cell = cell
        cell.button.setTitle(item.title, for: .normal)
        cell.button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchDown)
    }

    override func didSelectCell() {}
    
    override func cellSize() -> CGFloat {
        return cellheight
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        delegate?.buttonTableViewCellButtonPressed(sender)
    }
    
}
