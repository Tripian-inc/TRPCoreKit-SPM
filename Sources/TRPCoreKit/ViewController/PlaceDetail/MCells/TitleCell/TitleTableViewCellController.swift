//
//  TitleTableViewCellController.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/17/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import TRPUIKit

protocol TitleTableViewControllerDelegate: AnyObject {
    func addRemoveBtnPressed(_ addRemoveButtonStatus: AddRemoveNavButtonStatus?, _ addRemoveBtn: UIButton?)
    func navigationBtnPressed()
}

final class TitleTableViewCellController: GenericCellController<TitleTableViewCell> {
    private let item: TitleCellModel
    public weak var delegate: TitleTableViewControllerDelegate?
    
    private var cell: TitleTableViewCell?
    
    var cellheight = UITableView.automaticDimension
    
    init(titleCellModel: TitleCellModel) {
        self.item = titleCellModel
    }
    
    override func configureCell(_ cell: TitleTableViewCell) {
        self.cell = cell
        
        if item.sdkModeType != .Butterfly {
            //self.setNavigationButton(item.showNavigationButton, cell: cell)
            //self.setAddRemoveBtnStyle(item.addRemoveButtonStatus, cell)
            //cell.addRemoveBtn.addTarget(self, action: #selector(addRemoveBtnPressed), for: UIControl.Event.touchDown)
            //cell.navigationBtn.addTarget(self, action: #selector(navigationBtnPressed), for: UIControl.Event.touchDown)
        }
        
        cellheight = 30
        cell.titleLabel.text = item.title
        //Widht sürekli 0 geldiği için bug oluşuyor
        cellheight += heightForView(text: item.title, font: cell.titleLabel.font)
        
        if item.globalRating{
            //cell.showRating(item.starCount, item.reviewCount)
            cellheight += 28
        }
        
        if let explainText = item.explainText, explainText.length != 0 {
           // cell.showExplaineInRoute(explainText, item.globalRating)
            cellheight += 28
        }
        
    }
    
    
    
    override func didSelectCell() {}
    
    override func cellSize() -> CGFloat {
        return cellheight
    }
    
}

//MARK: Calculations
extension TitleTableViewCellController{
    private func setAddRemoveBtnStyle(_ type: AddRemoveNavButtonStatus?, _ cell: TitleTableViewCell) {
        var image: UIImage?
        guard let type = type else {return}
        switch type {
        case .add:
            image = TRPImageController().getImage(inFramework: "add_btn", inApp: TRPAppearanceSettings.Common.addButtonImage)
        case .remove:
            image = TRPImageController().getImage(inFramework: "remove_btn", inApp: TRPAppearanceSettings.Common.removeButtonImage)
        case .navigation:
            image = TRPImageController().getImage(inFramework: "navigation_btn", inApp: TRPAppearanceSettings.Common.navigationButtonImage)
        case .alternative:
            image = TRPImageController().getImage(inFramework: "alternative_poi_icon", inApp: TRPAppearanceSettings.Common.alternativePoiButtonImage)
        default:
            ()
        }
        //cell.addAddRemoveButton()
       // cell.addRemoveBtn.setImage(image, for: UIControl.State.normal)
    }
    
    private func setNavigationButton(_ showNavigation: Bool, cell: TitleTableViewCell){
        /*if showNavigation{
            if let image = TRPImageController().getImage(inFramework: "navigation_btn", inApp: TRPAppearanceSettings.Common.navigationButtonImage) {
                cell.navigationBtn.setImage(image, for: .normal)
            }
            cell.addNavigationButton()
        } */
    }
}

//MARK: Actions
extension TitleTableViewCellController{
    @objc func addRemoveBtnPressed() {
        //self.delegate?.addRemoveBtnPressed(item.addRemoveButtonStatus, cell?.addRemoveBtn)
    }
    
    @objc func navigationBtnPressed() {
        self.delegate?.navigationBtnPressed()
    }
}
