//
//  PlaceDetailCustomTagsCellController.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/19/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import TRPUIKit
import TRPRestKit

protocol PlaceDetailCustomTagsCellDelegate: AnyObject {
    func reportAProblemPressed()
}

final class PlaceDetailCustomTagsCellController: GenericCellController<PlaceDetailCustomTagsCell> {
    private let item: CustomTagsCellModel
    
    private var cell: PlaceDetailCustomTagsCell?
    
    public weak var delegate: PlaceDetailCustomTagsCellDelegate?
    
    init(customCellModel: CustomTagsCellModel) {
        self.item = customCellModel
    }
    
    override func configureCell(_ cell: PlaceDetailCustomTagsCell) {
        self.cell = cell
        cell.customLabel.text = item.title
        setImage(cell)
        setText(cell)
    }
    
    override func didSelectCell() {
        switch item.status {
        case .phone:
            item.title.makeACall()
            return
        case .web:
            if let url = URL(string: item.title) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            return
        case .reportaproblem:
            self.delegate?.reportAProblemPressed()
            return
        default:
            return
        }
    }
    
    override func cellSize() -> CGFloat {
        let height = heightForView(text: item.title, font: UIFont.systemFont(ofSize: 17))
        if height < 40{
            return 40
        }
        return height
    }
}

//MARK: - Calculations
extension PlaceDetailCustomTagsCellController{
    private func setImage(_ cell: PlaceDetailCustomTagsCell){
        switch item.status {
        case .cuisines:
            cell.cutomImageView.image = TRPImageController().getImage(inFramework: "place_detail_cuisine",
                                                                      inApp: TRPAppearanceSettings.PoiDetail.cuisineInListImage)
        case .feautures:
            cell.cutomImageView.image = TRPImageController().getImage(inFramework: "place_detail_features",
                                                                      inApp: TRPAppearanceSettings.PoiDetail.featuresInListImage)
        case .narrativeTags:
            cell.cutomImageView.image = TRPImageController().getImage(inFramework: "place_detail_information",
                                                                      inApp: TRPAppearanceSettings.PoiDetail.narrovingTagInListImage)
        case .money:
            cell.cutomImageView.image = TRPImageController().getImage(inFramework: "place_detail_money",
                                                                      inApp: TRPAppearanceSettings.PoiDetail.moneyInListImage)
        case .web:
            cell.cutomImageView.image = TRPImageController().getImage(inFramework: "place_detail_web",
                                                                      inApp: TRPAppearanceSettings.PoiDetail.webInListImage)
        case .phone:
            cell.cutomImageView.image = TRPImageController().getImage(inFramework: "place_detail_phone",
                                                                      inApp: TRPAppearanceSettings.PoiDetail.phoneInListImage)
        case .address:
            cell.cutomImageView.image = TRPImageController().getImage(inFramework: "place_detail_location",
                                                                      inApp: TRPAppearanceSettings.PoiDetail.locationInListImage)
        case .reportaproblem:
            cell.cutomImageView.image = nil
        case .makeAReservation:
            cell.cutomImageView.image = nil
        case .mustTry:
            cell.cutomImageView.image = TRPImageController().getImage(inFramework: "place_detail_must_try",
                                                                      inApp: TRPAppearanceSettings.PoiDetail.mustTryListImage)
            return
            
        }
    }
    
    private func setText(_ cell: PlaceDetailCustomTagsCell){
        switch item.status {
        case .phone:
            cell.customLabel.textColor = TRPColor.blue
            cell.customLabel.textAlignment = .left
            cell.customLabel.font = UIFont.systemFont(ofSize: 14)
            return
        case .web:
            cell.customLabel.textColor = TRPColor.blue
            cell.customLabel.textAlignment = .left
            cell.customLabel.font = UIFont.systemFont(ofSize: 14)
            return
        case .money:
            cell.customLabel.attributedText = getPrice(price: item.price ?? 0)
            cell.customLabel.textAlignment = .left
            return
        case .reportaproblem:
            cell.customLabel.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -40).isActive = true
            cell.customLabel.centerXAnchor.constraint(equalTo: cell.centerXAnchor, constant: 0).isActive = true

            cell.customLabel.text = "Report A Problem".toLocalized()
            cell.customLabel.textColor = TRPColor.darkGrey
            cell.customLabel.textAlignment = .center
            cell.customLabel.font = UIFont.systemFont(ofSize: 12)
            return
        default:
            cell.customLabel.textAlignment = .left
            cell.customLabel.font = UIFont.systemFont(ofSize: 14)
            return
        }
    }
    
    func getPrice(price: Int) -> NSMutableAttributedString {
        let boldPrice = String(repeating: "$" , count: 4)
        let largeAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),.foregroundColor: UIColor.darkGray]
        let smallAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 8),.foregroundColor: UIColor.lightGray]
        let attributedSentence = NSMutableAttributedString(string: boldPrice, attributes: smallAttributes)
        attributedSentence.setAttributes(largeAttributes, range: NSRange(location: 0, length: price))
        return attributedSentence
    }
}
