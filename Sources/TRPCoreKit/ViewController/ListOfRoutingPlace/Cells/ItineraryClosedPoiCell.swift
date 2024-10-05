//
//  ItineraryClosedPoiCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 21.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPUIKit

class ItineraryClosedPoiCell: ItineraryBaseCell {
 
    
    public lazy var alternativeButton: UIButton = {
        let btn = UIButton()
        let color = TRPColor.lightGrey
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(TRPColor.darkGrey, for: UIControl.State.normal)
        btn.addTarget(self, action: #selector(alternativeButtonPressed), for: .touchUpInside)
        let alternativesText = "Show Alternatives".toLocalized()
        btn.setTitle(" \(alternativesText) ", for: UIControl.State.normal)
        if let titleLabel = btn.titleLabel{
            titleLabel.font = UIFont.systemFont(ofSize: 9)
            titleLabel.textColor = UIColor.lightGray
        }
        btn.backgroundColor = .clear
        btn.layer.cornerRadius = 5
        btn.layer.borderWidth = 1
        btn.layer.borderColor = color.cgColor
        btn.heightAnchor.constraint(equalToConstant: 26).isActive = true
        btn.widthAnchor.constraint(equalToConstant: 100).isActive = true
        return btn
    }()
    
    public lazy var explaineText: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = TRPColor.pink
        label.font = UIFont.systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    public lazy var timeStepLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = TRPColor.darkGrey
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public let star = TRPStar(frame: CGRect(x: 0, y: 0, width: 20, height: 10))
  
    public var alternativeHandler: ButtonClicked?
    
    override func addViewInCenterStack(_ stack: UIStackView) {
        stack.addArrangedSubview(poiNameLabel)
        stack.addArrangedSubview(explaineText)
        
        mainStackView.addArrangedSubview(alternativeButton)
    }
    
    override func prepareForReuse() {
        poiImage.image = nil
        distanceInfoLabel.text = nil
        alternativeButton.isHidden = true
        alternativeButton.isUserInteractionEnabled = false
        bottomDistanceView.backgroundColor = TRPColor.ultraLightGrey.withAlphaComponent(0.7)
        setDistanceImage(type: .none)
    }
    
    @objc func alternativeButtonPressed() {
        alternativeHandler?()
    }
}
