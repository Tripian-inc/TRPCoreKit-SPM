//
//  OpeningHoursCell.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/18/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//


import TRPUIKit

final class OpeningHoursCell: UITableViewCell {
    
    lazy var openingHoursImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = TRPImageController().getImage(inFramework: "place_detail_calendar", inApp: TRPAppearanceSettings.PoiDetail.calendarInListImage)
        return imageView
    }()
    
    lazy var arrowImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 10).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 10).isActive = true
        imageView.contentMode = .center
        imageView.image = downArrowImage
        return imageView
    }()
    
    let downArrowImage = TRPImageController().getImage(inFramework: "down_arrow_gray", inApp: TRPAppearanceSettings.TripModeMapView.backInTopBarImage)
    
    let upArrowImage = TRPImageController().getImage(inFramework: "up_arrow_gray", inApp: TRPAppearanceSettings.TripModeMapView.backInTopBarImage)
    
    
    lazy var openingHoursLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = trpTheme.color.tripianTextPrimary
        label.font = trpTheme.font.body2
        label.numberOfLines = 1
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
        layoutIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setIcon(inFramework: String, inApp: String) {
        if let img = TRPImageController().getImage(inFramework: inFramework, inApp: TRPAppearanceSettings.PoiDetail.cuisineInListImage) {
//            let maskedImage = img.maskWithColor(color: trpTheme.color.extraMain)
            openingHoursImageView.image = img
        }
    }
    
    public func updateHeight(_ size: CGFloat) {
       
    }
}

//MARK: - UI Design
extension OpeningHoursCell {
    
    private func setup() {
        self.selectionStyle = .none
        setOpeningHoursImageView()
        setOpeningHoursLabel()
        setArrowImage()
    }
    
    private func setOpeningHoursImageView() {
        addSubview(openingHoursImageView)
        openingHoursImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        openingHoursImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        openingHoursImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        openingHoursImageView.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
    }
    
    private func setOpeningHoursLabel() {
        addSubview(openingHoursLabel)
        openingHoursLabel.leadingAnchor.constraint(equalTo: openingHoursImageView.trailingAnchor, constant: 8).isActive = true
        openingHoursLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        openingHoursLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
    }
    
    private func setArrowImage(){
        addSubview(arrowImage)
        arrowImage.leadingAnchor.constraint(equalTo: openingHoursLabel.trailingAnchor, constant: 10).isActive = true
        arrowImage.centerYAnchor.constraint(equalTo: openingHoursLabel.centerYAnchor, constant: 0).isActive = true
    }
}
