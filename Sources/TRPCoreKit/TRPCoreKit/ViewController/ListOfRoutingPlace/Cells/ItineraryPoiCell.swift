//
//  ItineraryPoiCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 21.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPUIKit

class ItineraryPoiCell: ItineraryBaseCell {
    
    lazy var topHorizontalStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = NSLayoutConstraint.Axis.horizontal
        stack.distribution = UIStackView.Distribution.fill
        return stack
    }()
    
    lazy var poiTypeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = TRPColor.darkGrey
        label.numberOfLines = 1
        label.text = ""
        return label
    }()
    
    lazy var priceRangeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 10)
        label.numberOfLines = 1
        label.textColor = UIColor.darkGray
        label.textAlignment = .left
        label.text = "".toLocalized()
        return label
    }()
    
    lazy var ratingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 10)
        label.numberOfLines = 1
        label.textColor = TRPColor.darkGrey
        label.textAlignment = .left
        label.text = " ()  "
        label.heightAnchor.constraint(equalToConstant: 14).isActive = true
        return label
    }()
    
    lazy var globalRatingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 10)
        label.numberOfLines = 1
        label.textColor = TRPColor.darkGrey
        label.textAlignment = .left
        label.text = TRPLanguagesController.shared.getLanguageValue(for: "global_rating")
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
    
    lazy var reactionView: ReactionView = {
        let view = ReactionView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.action = { [weak self] action in
            self?.action?(action)
        }
        return view
    }()

    var action: ((_ action: ReactionActionType) -> Void)?
    
    public lazy var alternativeButton: UIButton = {
        let btn = UIButton()
        let color = TRPColor.lightGrey
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(TRPColor.darkGrey, for: UIControl.State.normal)
        btn.addTarget(self, action: #selector(alternativeButtonPressed), for: .touchUpInside)
        let alternativesText = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.step.thumbs.replace.alternativeLocations")
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
    
    public lazy var timeStepLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = TRPColor.darkGrey
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public let star = TRPStar(frame: CGRect(x: 0, y: 0, width: 20, height: 10))
    
    var showGlobalRating: Bool = false {
        didSet {
            if showGlobalRating {
                star.isHidden = false
                ratingLabel.isHidden = false
                globalRatingLabel.isHidden = false
            }else {
                star.isHidden = true
                ratingLabel.isHidden = true
                globalRatingLabel.isHidden = true
            }
            setRatingStackView()
        }
    }
    
    public var alternativeHandler: ButtonClicked?
    
    override func addViewInCenterStack(_ stack: UIStackView) {
        stack.addArrangedSubview(poiNameLabel)
        stack.addArrangedSubview(topHorizontalStackView)
        topHorizontalStackView.addArrangedSubview(poiTypeLabel)
        topHorizontalStackView.addArrangedSubview(priceRangeLabel)
        mainStackView.addArrangedSubview(ratingStackView)
        mainStackView.addArrangedSubview(reactionView)
        combineBottom()
    }
    
    override func prepareForReuse() {
        poiImage.image = nil
        priceRangeLabel.text = ""
        distanceInfoLabel.text = nil
        alternativeButton.isHidden = true
        alternativeButton.isUserInteractionEnabled = false
        bottomDistanceView.backgroundColor = TRPColor.ultraLightGrey.withAlphaComponent(0.7)
        setDistanceImage(type: .none)
    }
    
    private func setRatingStackView(){
        guard mainStackView.isDescendant(of: self) else {return}
        if showGlobalRating{
            //Set Rate View
            ratingStackView.addArrangedSubview(globalRatingLabel)
            star.backgroundColor = UIColor.red
            star.show()
            ratingStackView.addArrangedSubview(ratingLabel)
            ratingStackView.addArrangedSubview(star)
        }
    }
    
    func setRating(starCount: Int, review: Int) {
        star.setRating(starCount)
        ratingLabel.text = " (\(review)) "
    }
    
    @objc func alternativeButtonPressed() {
        alternativeHandler?()
    }
}
