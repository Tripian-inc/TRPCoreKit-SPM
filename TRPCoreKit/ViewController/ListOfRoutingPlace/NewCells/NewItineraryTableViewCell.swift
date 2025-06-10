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
    @IBOutlet weak var uberBtn: TRPBtnSmall!
    @IBOutlet weak var buyTicketBtn: TRPBtnSmall!
    @IBOutlet weak var orderContainer: UIView!
    @IBOutlet weak var categoryLbl: UILabel!
    @IBOutlet weak var ratingView: UIStackView!
    @IBOutlet weak var emptyRatingView: UIView!
    @IBOutlet weak var ratingCountLbl: UILabel!
    @IBOutlet weak var reviewCountLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    
    @IBOutlet weak var reactionStackView: UIStackView!
    @IBOutlet weak var thumbsDownBtn: UIButton!
    @IBOutlet weak var thumbsUpBtn: UIButton!
    @IBOutlet weak var thumbsSpacerView: UIView!
    @IBOutlet weak var removeBtn: UIButton!
    @IBOutlet weak var replaceBtn: UIButton!
    @IBOutlet weak var thumbsDownSelected: UIButton!
    @IBOutlet weak var thumbsUpSelected: UIButton!
    
    @IBOutlet weak var distanceView: UIStackView!
    @IBOutlet weak var distanceImg: UIImageView!
    @IBOutlet weak var distanceLbl: UILabel!
    
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var timeView: UIView!
    
    var action: ((_ action: ReactionActionType) -> Void)?
    var bookARide: (() -> Void)?
    var buyTicket: (() -> Void)?
    var changeTime: (() -> Void)?
    
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
        placeImage.layer.cornerRadius = 40
        placeImage.layer.masksToBounds = true
        placeImage.image = nil
        placeImage.sd_cancelCurrentImageLoad()
        
        distanceLbl.font = trpTheme.font.body3
        distanceLbl.textColor = trpTheme.color.tripianTextPrimary
        
        categoryLbl.font = trpTheme.font.body3
        categoryLbl.textColor = trpTheme.color.tripianTextPrimary
        
        ratingCountLbl.font = trpTheme.font.semiBold12
        ratingCountLbl.textColor = trpTheme.color.tripianTextPrimary
        
        reviewCountLbl.font = trpTheme.font.body3
        reviewCountLbl.textColor = trpTheme.color.extraMain
        
        priceLbl.font = trpTheme.font.body3
        priceLbl.textColor = trpTheme.color.tripianTextPrimary
        
        timeLbl.font = trpTheme.font.body3
        timeLbl.textColor = trpTheme.color.tripianPrimary
        
        orderContainer.layer.cornerRadius = 10
    }

    
    
    func config(_ model: ItineraryUIModel) {
        placeNameLbl.text = model.poiName
        
        categoryLbl.isHidden = model.category.isEmpty
        categoryLbl.text = model.category
        
        setupImageView(model: model)
        setupTimeView(model: model)
        setupDistanceView(model: model)
        setupActionButtons(model: model)
        setupRatingView(model: model)
        setupReactionView(model: model)
        
        if model.isHotel {
            ratingView.isHidden = true
            orderContainer.isHidden = true
        }
    }
    
    private func setupImageView(model: ItineraryUIModel) {
        orderContainer.isHidden = false
        orderLbl.isHidden = false
        orderLbl.text = "\(model.order)"
        
        placeImage.tag = model.order
        
        if model.isHotel {
            setImageForHomeBase()
        } else {
            placeImage.sd_setImage(with: model.image, completed: { [weak self] _,_,_,_ in
                if self?.placeImage.tag == 0 {
                    self?.setImageForHomeBase()
                }
            })
        }
    }
    
    private func setImageForHomeBase() {
        placeImage.backgroundColor = trpTheme.color.tripianBlack
        placeImage.image = TRPImageController().getImage(inFramework: "black_homebase", inApp: "black_homebase")
    }
    
    private func setupDistanceView(model: ItineraryUIModel) {
        if let distance = model.readableDistance, let time = model.readableTime  {
            distanceView.isHidden = false
            let userCar = model.userCar
            distanceLbl.text = TRPLanguagesController.shared.getLanguageValue(for: "duration_format", with: time, distance) //: TRPLanguagesController.shared.getLanguageValue(for: "walk_duration_format", with: time, distance)
            let distanceImage = userCar ? "icon_car" : "icon_walking"
            if let image = TRPImageController().getImage(inFramework: distanceImage, inApp: distanceImage) {
                distanceImg.image = image
            }
        } else {
            distanceView.isHidden = true
            distanceLbl.text = ""
        }
    }
    
    private func setupTimeView(model: ItineraryUIModel) {
        var timeText: String = ""
        if !model.startTime.isEmpty {
            timeText = model.startTime
        }
        if !model.endTime.isEmpty {
            if !timeText.isEmpty {
                timeText = timeText + " - "
            }
            timeText = timeText + model.endTime
        }
        timeLbl.text = timeText
        timeView.isHidden = timeText.isEmpty
    }
    
    private func setupRatingView(model: ItineraryUIModel) {
        
        ratingView.isHidden = model.rating < 1
        emptyRatingView.isHidden = !ratingView.isHidden
        ratingCountLbl.text = String(model.rating)
        reviewCountLbl.text = "(\(model.reviewCount))"
        
        priceLbl.isHidden = model.price <= 0
        if model.price > 0 {
            priceDolarSign = model.price
            priceLbl.attributedText = $priceDolarSign.generateDolarSign(largeFontSize: 12, smallFontSize: 12)
        }
    }
    
    private func setupReactionView(model: ItineraryUIModel) {
        [thumbsDownBtn,thumbsUpBtn,thumbsSpacerView, removeBtn, replaceBtn, thumbsDownSelected, thumbsUpSelected].forEach{ $0?.isHidden = true }
        
        switch  model.reaction {
        case .thumbsUp:
            thumbsUpSelected.isHidden = false
            thumbsSpacerView.isHidden = false
        case .thumbsDown:
            thumbsDownSelected.isHidden = false
            removeBtn.isHidden = false
            replaceBtn.isHidden = !model.canReplace
            thumbsSpacerView.isHidden = true
        case .neutral:
            ()
        case .none:
            thumbsDownBtn.isHidden = false
            thumbsUpBtn.isHidden = false
            thumbsSpacerView.isHidden = false
        }
        reactionStackView.isHidden = model.isHotel
    }
    
    private func setupActionButtons(model: ItineraryUIModel) {
        uberBtn.setTitle(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.direction"), for: .normal)
        uberBtn.isHidden = true
        uberBtn.addTarget(self, action: #selector(bookArideAction), for: .touchUpInside)
        
        buyTicketBtn.isHidden = model.bookingProduct == nil
        buyTicketBtn.setTitle(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.step.poi.tourTicket.ticket.title"), for: .normal)
        buyTicketBtn.addTarget(self, action: #selector(buyTicketAction), for: .touchUpInside)
        
        if model.isProduct {
            buyTicketBtn.setTitle("nexustours", for: .normal)
            buyTicketBtn.isHidden = false
            
        }
    }
    
    @objc func bookArideAction() {
        bookARide?()
    }
    
    @objc func buyTicketAction() {
        buyTicket?()
    }
    
    @IBAction func changeTimeAction(_ sender: Any) {
        changeTime?()
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
}
