//
//  NewItineraryTableViewCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-05-25.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit

@objc(SPMNewItineraryTableViewCell)
class NewItineraryTableViewCell: UITableViewCell {
    
    @PriceIconWrapper
    private var priceDolarSign = 0
    
    @IBOutlet weak var placeImage: UIImageView!
    @IBOutlet weak var orderLbl: UILabel!
    @IBOutlet weak var placeNameLbl: UILabel!
    @IBOutlet weak var distanceLbl: UILabel!
    @IBOutlet weak var uberBtn: UIButton!
    @IBOutlet weak var orderContainer: UIView!
    @IBOutlet weak var categoryLbl: UILabel!
    @IBOutlet weak var starView: UIView!
    @IBOutlet weak var ReviewCount: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var travelImage: UIImageView!
    
    @IBOutlet weak var thumbsDownBtn: UIButton!
    @IBOutlet weak var thumbsUpBtn: UIButton!
    @IBOutlet weak var thumbsSpacerView: UIView!
    @IBOutlet weak var removeBtn: UIButton!
    @IBOutlet weak var replaceBtn: UIButton!
    @IBOutlet weak var thumbsDownSelected: UIButton!
    @IBOutlet weak var thumbsUpSelected: UIButton!
    
    
    var action: ((_ action: ReactionActionType) -> Void)?
    
    typealias ButtonClicked = () -> Void
    public var uberHandler: ButtonClicked?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }

    private func commonInit() {
        selectionStyle = .none
        placeNameLbl.font = trpTheme.font.header2
        placeNameLbl.textColor = trpTheme.color.tripianBlack
        
        
        
        orderLbl.font = trpTheme.font.body2
        orderLbl.textColor = UIColor.white
        
        placeImage.backgroundColor = trpTheme.color.extraMain
        placeImage.layer.cornerRadius = 32
        placeImage.layer.masksToBounds = true
        
        distanceLbl.font = trpTheme.font.body3
        distanceLbl.textColor = trpTheme.color.tripianTextPrimary
        
        categoryLbl.font = trpTheme.font.body3
        categoryLbl.textColor = trpTheme.color.tripianTextPrimary
        
        ReviewCount.font = trpTheme.font.body3
        ReviewCount.textColor = trpTheme.color.tripianTextPrimary
        
        priceLbl.font = trpTheme.font.body3
        priceLbl.textColor = trpTheme.color.tripianTextPrimary
        
        uberBtn.titleLabel?.font = trpTheme.font.body3
        uberBtn.titleLabel?.textColor = .white
        uberBtn.backgroundColor = trpTheme.color.blue
        uberBtn.layer.cornerRadius = 12
        uberBtn.layer.masksToBounds = true
        
        uberBtn.setTitle(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.direction"), for: .normal)
        
        removeBtn.setTitle(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.step.thumbs.remove"), for: .normal)
        replaceBtn.setTitle(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.step.thumbs.replace.title"), for: .normal)
        
        removeBtn.layer.cornerRadius = 17
        removeBtn.layer.borderWidth = 0.5
        removeBtn.layer.borderColor = trpTheme.color.extraShadow.cgColor
        removeBtn.backgroundColor = trpTheme.color.extraSub
        removeBtn.setTitleColor(trpTheme.color.tripianTextPrimary, for: .normal)
        removeBtn.titleLabel?.font = trpTheme.font.body3
        
        replaceBtn.layer.cornerRadius = 17
        replaceBtn.layer.borderWidth = 0.5
        replaceBtn.layer.borderColor = trpTheme.color.extraShadow.cgColor
        replaceBtn.backgroundColor = trpTheme.color.extraSub
        replaceBtn.setTitleColor(trpTheme.color.tripianTextPrimary, for: .normal)
        replaceBtn.titleLabel?.font = trpTheme.font.body3
        
        orderContainer.layer.cornerRadius = 10
    }

    
    
    func config(_ model: ItineraryUIModel) {
        placeNameLbl.text = model.poiName
        
        orderContainer.isHidden = false
        orderLbl.isHidden = false
        orderLbl.text = "\(model.order)"
        
        uberBtn.isHidden = !model.userCar
        
        [thumbsDownBtn,thumbsUpBtn,thumbsSpacerView, removeBtn, replaceBtn, thumbsDownSelected, thumbsUpSelected].forEach{ $0?.isHidden = true }
        
        if let distance = model.readableDistance, let time = model.readableTime  {
            let userCar = model.userCar
            distanceLbl.text = "\(distance) \(TRPLanguagesController.shared.getLanguageValue(for: "km")) - \(time) \(TRPLanguagesController.shared.getLanguageValue(for: "min"))"
            distanceLbl.adjustsFontSizeToFitWidth = true
            travelImage.image = userCar ? TRPImageController().getImage(inFramework: "icon_car", inApp: "icon_car") : TRPImageController().getImage(inFramework: "icon_walking", inApp: "icon_walking")
            travelImage.isHidden = false
            //let distanceImage = userCar ? ItineraryDistanceType.car : ItineraryDistanceType.walking
            //cell.setDistanceImage(type: distanceImage)
        } else {
            distanceLbl.text = ""
            travelImage.isHidden = true
        }
        
        if model.isHotel {
            placeImage.image = TRPImageController().getImage(inFramework: "black_homebase", inApp: "black_homebase")
        } else {
            placeImage.sd_setImage(with: model.image, completed: nil)
        }
        
        
        categoryLbl.text = model.category
        
        if model.reviewCount != 0 {
            ReviewCount.isHidden = false
            ReviewCount.text = "(\(model.reviewCount))"
        }else {
            ReviewCount.isHidden = true
        }
        
        if model.price > 0 {
            priceDolarSign = model.price
            priceLbl.isHidden = false
            priceLbl.attributedText = $priceDolarSign.generateDolarSign(largeFontSize: 12, smallFontSize: 12)
            
        } else {
            priceLbl.isHidden = true
        }
        
        if model.star != 0 {
            starView.isHidden = false
            let newStarView = TRPStarView(frame: CGRect(x: 0, y: 8, width: 94, height: 12))
            newStarView.star = model.star
            starView.addSubview(newStarView)
        }
        
        
        switch  model.reaction {
        case .thumbsUp:
            thumbsUpSelected.isHidden = false
            thumbsSpacerView.isHidden = false
        case .thumbsDown:
            thumbsDownSelected.isHidden = false
            removeBtn.isHidden = false
            replaceBtn.isHidden = !model.canReplace
            thumbsSpacerView.isHidden = false
        case .neutral:
            ()
        case .none:
            thumbsDownBtn.isHidden = false
            thumbsUpBtn.isHidden = false
            thumbsSpacerView.isHidden = false
        }
        
        
        if model.isHotel {
            thumbsDownBtn.isHidden = true
            thumbsUpBtn.isHidden = true
            thumbsSpacerView.isHidden = true
            starView.isHidden = true
            priceLbl.isHidden = true
            ReviewCount.isHidden = true
            orderLbl.isHidden = true
            orderContainer.isHidden = true
        }
    }
    
    @IBAction func thumbsDownPressed(_ sender: UIButton) {
        action?(.thumbsDown)
    }
    @IBAction func thumbsDownUndoPressed(_ sender: Any) {
        action?(.undo)
    }
    
    @IBAction func thumbsUpPressed(_ sender: Any) {
        action?(.thumbsUp)
    }
    
    @IBAction func thumbsUpUndoPressed(_ sender: Any) {
        action?(.undo)
    }
    
    @IBAction func removePressed(_ sender: Any) {
        action?(.remove)
    }
    
    @IBAction func replacePressed(_ sender: Any) {
        action?(.replace)
    }
    @IBAction func uberPressed(_ sender: Any) {
        uberHandler?()
    }
}
