//
//  PlaceDetailCellControllerFactory.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/17/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit



protocol PlaceDetailCellControllerFactoryDelegate: AnyObject {
    func favPressed(cell: ImageCarouselTableViewCell?)
    func addRemoveBtnPressed(_ addRemoveButtonStatus: AddRemoveNavButtonStatus?, _ addRemoveBtn: UIButton?)
    func navigationBtnPressed()
    func reportAProblemPressed()
    func makeAReservationPressed()
}

final class PlaceDetailCellControllerFactory {
    
    public weak var delegate: PlaceDetailCellControllerFactoryDelegate?
    
    func registerCells(on tableView: UITableView) {
        ImageTableCellController.registerCell(on: tableView)
        TitleTableViewCellController.registerCell(on: tableView)
       // DescriptionTableViewCellController.registerCell(on: tableView)
        OpeningHoursCellController.registerCell(on: tableView)
        PlaceDetailCustomTagsCellController.registerCell(on: tableView)
        MapTableViewCellController.registerCell(on: tableView)
        ButtonTableViewCellController.registerCell(on: tableView)
    }
    /*
    func cellControllers(from elements: [FeedElement]) -> [TableCellController]? {
        return elements.map { (element) in
            switch element {
            case .image(let imageCellModel):
                let imageCellController = ImageTableCellController(imageCellModel: imageCellModel)
                imageCellController.delegate = self
                return imageCellController
            case .title(let titleCellModel):
                let titleCellController = TitleTableViewCellController(titleCellModel: titleCellModel)
                titleCellController.delegate = self
                return titleCellController
            case .description(let descriptionCellModel):
                return nil
            case .openingHours(let openingHoursCellModel):
                return OpeningHoursCellController(openingHoursCellModel: openingHoursCellModel)
            case .customTagsCell(let customTagsCellModel):
                let customCells = PlaceDetailCustomTagsCellController(customCellModel: customTagsCellModel)
                customCells.delegate = self
                return customCells
            case .map(let mapViewCellModel):
                return MapTableViewCellController(mapCellModel: mapViewCellModel)
            case .button(let buttonCellModel):
                let buttonCell = ButtonTableViewCellController(cellModel: buttonCellModel)
                buttonCell.delegate = self
                return buttonCell
            }
        }
    }
 */
    
}



extension PlaceDetailCellControllerFactory: ImageTableViewControllerDelegate, TitleTableViewControllerDelegate, PlaceDetailCustomTagsCellDelegate, ButtonTableViewCellControllerDelegate{
    
    
    //MARK: Add Remove Status
    func addRemoveBtnPressed(_ addRemoveButtonStatus: AddRemoveNavButtonStatus?, _ addRemoveBtn: UIButton?) {
        if let addRemoveBtn = addRemoveBtn {
            delegate?.addRemoveBtnPressed(addRemoveButtonStatus, addRemoveBtn)
        }
    }
    
    //MARK: Navigation
    func navigationBtnPressed() {
        delegate?.navigationBtnPressed()
    }
    
    //MARK: Favorite Button
    func favPressed(cell: ImageCarouselTableViewCell?) {
        if let cell = cell{
            delegate?.favPressed(cell: cell)
        }
    }
    
    //MARK: Report A Problem
    func reportAProblemPressed() {
        delegate?.reportAProblemPressed()
    }
    
    func buttonTableViewCellButtonPressed(_ sender: UIButton) {
        delegate?.makeAReservationPressed()
    }
}



