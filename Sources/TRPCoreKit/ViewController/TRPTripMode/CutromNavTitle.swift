//
//  CutromNavTitle.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-05-21.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit
final class CustomNavTitle: UIView {
    
    lazy var cityNameLbl: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 1
        lbl.textAlignment = .center
        lbl.textColor = trpTheme.color.tripianTextPrimary
        lbl.font = trpTheme.font.header2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    lazy var dateLbl: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 1
        lbl.textAlignment = .center
        lbl.textColor = trpTheme.color.tripianBlack
        lbl.font = trpTheme.font.body3
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    lazy var downImage: UIImageView = {
        let image = UIImageView(image: TRPImageController().getImage(inFramework: "icon_down_orange",
                                                                     inApp: TRPAppearanceSettings.Common.addButtonImage))
        image.contentMode = UIView.ContentMode.scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    lazy var vStackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        let hStack = UIStackView(arrangedSubviews: [dateLbl,downImage])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = -4
        hStack.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        hStack.isLayoutMarginsRelativeArrangement = true

        vStackView = UIStackView(arrangedSubviews: [cityNameLbl, hStack])
        vStackView.axis = .vertical
        vStackView.alignment = .center
//        [cityNameLbl, dateLbl, downImage].forEach{addSubview($0)}
//        cityNameLbl.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
//        cityNameLbl.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
//        cityNameLbl.topAnchor.constraint(equalTo: topAnchor, constant: 4).isActive = true
//        dateLbl.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -8).isActive = true
//        dateLbl.topAnchor.constraint(equalTo: cityNameLbl.bottomAnchor, constant: 0).isActive = true
//        downImage.leadingAnchor.constraint(equalTo: dateLbl.trailingAnchor, constant: 2).isActive = true
//        downImage.centerYAnchor.constraint(equalTo: dateLbl.centerYAnchor, constant: 0).isActive = true
    }
    
    
}
