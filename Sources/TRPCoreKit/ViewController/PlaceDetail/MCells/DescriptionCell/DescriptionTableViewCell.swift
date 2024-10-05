//
//  DescriptionTableViewCell.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/17/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import TRPUIKit



final class ExpandableTableViewCell: UITableViewCell {
    
    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var descLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = trpTheme.color.tripianTextPrimary
        label.font = trpTheme.font.body2
        label.numberOfLines = 2
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
        layoutIfNeeded()
    }
    
    public func setIcon(inFramework: String, inApp: String) {
        if let img = TRPImageController().getImage(inFramework: inFramework, inApp: TRPAppearanceSettings.PoiDetail.cuisineInListImage) {
//            let maskedImage = img.maskWithColor(color: trpTheme.color.extraMain)
            iconImageView.image = img
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

//MARK: - UI Design
extension ExpandableTableViewCell {
    
    fileprivate func setup() {
        self.selectionStyle = .none
        setDescImageView()
        setDescLabel()
    }
    
    fileprivate func setDescImageView() {
        addSubview(iconImageView)
        iconImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
    }
    
    fileprivate func setDescLabel() {
        addSubview(descLabel)
        descLabel.topAnchor.constraint(equalTo: topAnchor,
                                       constant: 12).isActive = true
        descLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor,
                                           constant: 8).isActive = true
        descLabel.trailingAnchor.constraint(equalTo: trailingAnchor,
                                            constant: -10).isActive = true
        descLabel.bottomAnchor.constraint(equalTo: bottomAnchor,
                                          constant: -16).isActive = true
    }
}
