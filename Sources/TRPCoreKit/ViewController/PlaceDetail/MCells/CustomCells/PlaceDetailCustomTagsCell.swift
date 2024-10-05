//
//  PlaceDetailCustomTagsCell.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/19/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import TRPUIKit

final class PlaceDetailCustomTagsCell: UITableViewCell {
   
    private var status: PlaceDetailCustomCellStatus? = nil
    
    lazy var cutomImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        if let img = TRPImageController().getImage(inFramework: "place_detail_cuisine_bold", inApp: TRPAppearanceSettings.PoiDetail.cuisineInListImage) {
            imageView.image = img
        }
        return imageView
    }()
    
    lazy var customLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.textColor = trpTheme.color.tripianTextPrimary
        lbl.font = trpTheme.font.body2
        lbl.numberOfLines = 0
        return lbl
    }()
    
    func setStatus(with status: PlaceDetailCustomCellStatus) {
        self.status = status
    }
    
    var imageWidth: NSLayoutConstraint?
    var imageHeight: NSLayoutConstraint?
    var imageleading: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
        layoutIfNeeded()
    }
    
    public func setIcon(inFramework: String, inApp: String) {
        if let img = TRPImageController().getImage(inFramework: inFramework, inApp: TRPAppearanceSettings.PoiDetail.cuisineInListImage) {
            
            let maskedImage = img.maskWithColor(color: trpTheme.color.extraMain)
            cutomImageView.image = maskedImage
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public func setImageSize(w: CGFloat, h: CGFloat) {
        imageHeight?.constant = h
        imageWidth?.constant = w
        imageleading?.constant = 11
    }
}

//MARK: - UI Design
extension PlaceDetailCustomTagsCell {
    
    fileprivate func setup() {
        self.selectionStyle = .none
        setImageView()
        setLabel()
    }
    
    fileprivate func setImageView() {
        addSubview(cutomImageView)
        imageWidth = cutomImageView.widthAnchor.constraint(equalToConstant: 24)
        imageHeight = cutomImageView.heightAnchor.constraint(equalToConstant: 24)
        imageleading = cutomImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12)
        imageHeight?.isActive = true
        imageWidth?.isActive = true
        imageleading?.isActive = true
        cutomImageView.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
    }
    
    fileprivate func setLabel() {
        addSubview(customLabel)
        customLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
        customLabel.leadingAnchor.constraint(equalTo: cutomImageView.trailingAnchor, constant: 8).isActive = true
        customLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        customLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
    }
}
