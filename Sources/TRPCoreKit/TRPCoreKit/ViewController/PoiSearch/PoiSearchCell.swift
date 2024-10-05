//
//  PoiSearchCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 27.02.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
import TRPUIKit
class PoiSearchCell: UITableViewCell {
    
    var showGlobalRating: Bool = false {
        didSet {
            if showGlobalRating {
                star.isHidden = false
                ratingLabel.isHidden = false
                globalRatingLabel.isHidden = false
                ratingStackView.isHidden = false
                poiSubTypeLabel.isHidden  = false
            }else {
                star.isHidden = true
                ratingLabel.isHidden = true
                globalRatingLabel.isHidden = true
                ratingStackView.isHidden = true
                poiSubTypeLabel.isHidden = true
            }
        }
    }
    lazy var mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = NSLayoutConstraint.Axis.vertical
        stack.distribution = UIStackView.Distribution.equalSpacing
        stack.alignment = UIStackView.Alignment.leading
        stack.spacing = 8
        return stack
    }()
    
    lazy var poiNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 1
        label.textColor = UIColor.darkGray
        label.text = ""
        return label
    }()
    
    lazy var poiTypeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.darkGray
        label.numberOfLines = 1
        label.text = ""
        return label
    }()
    
    lazy var poiSubTypeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 10)
        label.numberOfLines = 1
        label.textColor = UIColor.lightGray
        label.text = ""
        return label
    }()
    
    lazy var ratingStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = NSLayoutConstraint.Axis.horizontal
        stack.distribution = .fill
        stack.alignment = UIStackView.Alignment.leading
        return stack
    }()
    
    lazy var globalRatingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 10)
        label.numberOfLines = 1
        label.textColor = UIColor.lightGray
        label.textAlignment = .left
        label.text = TRPLanguagesController.shared.getLanguageValue(for: "global_rating")
        return label
    }()
    
    lazy var ratingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 10)
        label.numberOfLines = 1
        label.textColor = UIColor.lightGray
        label.textAlignment = .left
        label.text = " (   )  "
        return label
    }()
    
    lazy var distanceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 1
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        label.text = "Distance".toLocalized()
        return label
    }()
    
    @PriceIconWrapper
    private var dolarSignIcon = 0
    
    public let star = TRPStar(frame: CGRect(x: 0, y: 0, width: 20, height: 10))
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(mainStackView)
        addSubview(distanceLabel)
        
        mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: distanceLabel.leadingAnchor, constant: 4).isActive = true
        mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
        //mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true
        mainStackView.addArrangedSubview(poiNameLabel)
        mainStackView.addArrangedSubview(poiTypeLabel)
        mainStackView.addArrangedSubview(poiSubTypeLabel)
        
        distanceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        distanceLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
        
        mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
    }
    
    
    public func setRatingAndStar(rating:Int, starCount: Float) {
        ratingLabel.text = " (\(rating))  "
        mainStackView.addArrangedSubview(ratingStackView)
        ratingStackView.addArrangedSubview(globalRatingLabel)
        ratingStackView.addArrangedSubview(ratingLabel)
        star.show()
        ratingStackView.addArrangedSubview(star)
        star.setRating(Int(starCount))
    }
    
    public func setTypeAndPrice(type: String, priceCount: Int) {
        let typeAttributeStyle = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)]
        let mainAttribute = NSMutableAttributedString(string: type, attributes: typeAttributeStyle)
        if priceCount > 0 {
            dolarSignIcon = priceCount
            let priceLbl = $dolarSignIcon.generateDolarSign(largeFontSize: 12, smallFontSize: 12)
            let subTypeAttributeStyle = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)]
            let subTypeAttribute = NSMutableAttributedString(string: " - ", attributes: subTypeAttributeStyle)
            mainAttribute.append(subTypeAttribute)
            mainAttribute.append(priceLbl)
        }
        poiTypeLabel.attributedText = mainAttribute
    }
    
    private func setDistanceAttributed(userCar:Bool, distance: String, time: String) -> NSMutableAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let extractedImageAttribute = NSMutableAttributedString()
        let attachment:NSTextAttachment = NSTextAttachment()
        attachment.image = userCar ? TRPImageController().getImage(inFramework: "drive", inApp: TRPAppearanceSettings.ItineraryUserDistance.taxi)!.maskWithColor(color: TRPColor.taxiYellow)!.imageWithSize(scaledToSize: CGSize(width: 16, height: 16)) : TRPImageController().getImage(inFramework: "man-walking-directions-button", inApp: TRPAppearanceSettings.ItineraryUserDistance.walkingMan)?.imageWithSize(scaledToSize: CGSize(width: 16, height: 16))
        let attachmentString:NSAttributedString = NSAttributedString(attachment: attachment)
        extractedImageAttribute.append(attachmentString)
        
        let attributes = [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 10),
                          NSAttributedString.Key.foregroundColor : TRPColor.darkGrey,
                          NSAttributedString.Key.paragraphStyle: paragraph]
        let distanceText = userCar ? "\(distance) km " : "\(distance) km - \(time) min "
        let distanceAttributed = NSMutableAttributedString(string: userCar ? "   \(distanceText)" : "   \(distanceText)",  attributes: attributes)
        extractedImageAttribute.append(distanceAttributed)
        
        return extractedImageAttribute
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
