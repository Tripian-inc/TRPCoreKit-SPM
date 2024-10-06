//
//  PoiDetailOfferCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 29.08.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

@objc(SPMPoiDetailOfferCell)
class PoiDetailOfferCell: UITableViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var offerImage: UIImageView!
    @IBOutlet weak var imInBtn: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subLbl: UILabel!
    @IBOutlet weak var subLbl2: UILabel!
    @IBOutlet weak var typeLbl: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func prepareForReuse() {
        imInBtn.removeTarget(nil, action: nil, for: .allEvents)
    }
   
    
    private func setupUI() {
        contentView.backgroundColor = UIColor.clear

//        imInBtn.layer.backgroundColor = appTheme.color.deepPink.cgColor
//        imInBtn.layer.cornerRadius = imInBtn.frame.height / 2
        imInBtn.setTitleColor(.white, for: .normal)
        imInBtn.titleLabel?.font = trpTheme.font.body2
        imInBtn.setTitle("Opt-in", for: .normal)
        
        offerImage.layer.cornerRadius = 20
        offerImage.backgroundColor = trpTheme.color.extraShadow
        containerView.layer.cornerRadius = 30
        offerImage.contentMode = .scaleAspectFill
        offerImage.clipsToBounds = true
        
        
        titleLabel.font = trpTheme.font.header2
        titleLabel.textColor = trpTheme.color.tripianBlack
        
        subLbl.font = trpTheme.font.body3
        subLbl.textColor = trpTheme.color.tripianTextPrimary
        subLbl.numberOfLines = 2
        subLbl2.font = trpTheme.font.body3
        subLbl2.textColor = trpTheme.color.tripianTextPrimary
        
        typeLbl.font = trpTheme.font.body2
        typeLbl.textColor = trpTheme.color.tripianBlack
        
        containerView.backgroundColor = UIColor.white
        containerView.layer.shadowColor = UIColor.lightGray.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowRadius = 5
    }

    
    public func configurate(_ model: PoiOfferCellModel) {
        titleLabel.text = model.offerName
        subLbl.text = model.date
        subLbl2.text = model.description
        typeLbl.text = model.type
        
        if !model.optIn {
            imInBtn.setTitle("Opt-in", for: .normal)
            imInBtn.isHidden = false
        } else {
            imInBtn.setTitle("Opt-out", for: .normal)
            imInBtn.isHidden = false
        }
        
        if model.status == "active" {
            imInBtn.isEnabled = true
            imInBtn.alpha = 1
        } else {
            imInBtn.isEnabled = false
            imInBtn.alpha = 0.6
        }
        
        DispatchQueue.main.async {
//            let link = TRPImageResizer.generate(withUrl: model.imageUrl, standart: .small2, type: "Place")
            self.offerImage.sd_setImage(with: URL(string: model.imageUrl ), completed: nil)
        }
        
    }
}



public struct PoiOfferCellModel {
    
    var offerId: Int
    var offerName: String
    var imageUrl: String
    var description: String = ""
    var date: String = ""
    var poiId: String
    var type: String = ""
    var optIn: Bool
    
    var startDate: Date?
    var endDate: Date?
    var status: String?
    var optInClaimDate: String? = ""
    var poi: TRPPoi?
}

extension PoiOfferCellModel {
    
    init(offer: TRPOffer) {
        self.offerId = offer.id
        self.offerName = offer.title
        self.poiId = offer.poiId
        self.imageUrl = offer.imageUrl ?? ""
        self.optIn = offer.optIn
        self.optInClaimDate = offer.optInClaimDate
        
        self.type = getType(offer).capitalizingFirstLetter()
        
        if let startDate = offer.timeframe?.start.toDate(format: "yyyy-MM-dd HH:mm:ss"),
           let endDate = offer.timeframe?.end.toDate(format: "yyyy-MM-dd HH:mm:ss"){
            
            self.startDate = startDate
            self.endDate = endDate
            
            let startTime = startDate.toString(format: "dd MMM h:mm a", dateStyle: nil, timeStyle: nil)
            let endTime = endDate.toString(format: "dd MMM h:mm a", dateStyle: nil, timeStyle: nil)
            self.date = "From: " + startTime + "\nTo: " + endTime
            
        } else {
            self.date = (offer.timeframe?.start ?? "") + " - " + (offer.timeframe?.end ?? "")
        }
        
        self.description = offer.caption
        self.status = offer.status.rawValue
    }
    
    private func getType(_ offer: TRPOffer) -> String {
        return offer.productType?.receiveMethod.getMethodName() ?? ""
    }
    
    public mutating func setClaimDate() {
        if let optInClaimDate = optInClaimDate?.toDate(format: "yyyy-MM-dd") {
            let claimDate = optInClaimDate.toString(format: "dd MMM yyyy")
            self.date = "Claim date: " + claimDate
        }
    }
}
