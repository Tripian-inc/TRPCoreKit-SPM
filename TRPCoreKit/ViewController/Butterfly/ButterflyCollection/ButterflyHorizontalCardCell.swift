//
//  ButterflyHorizontalCardCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 1.05.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
class ButterflyHorizontalCardCell: UICollectionViewCell {
    
    enum ThumbsType {
        case noSelect, upSelected
    }
    
    public var isPlaceLiked: Bool = false {
        didSet {
            let type: ThumbsType = self.isPlaceLiked ? .upSelected : .noSelect
            switchThumbsButton(type: type)
        }
    }
    
    private var mainImageHeight: CGFloat {
        TRPAppearanceSettings.Butterfly.imageHeight
    }
    public var thumbsDownPressedHandler: (() -> Void)?
    public var thumbsUpPressedHandler: ((_ current: ThumbsType) -> Void)?
    
    
    lazy var dayInfoLabel: UILabel = {
        let lbl = UILabel(frame: .zero)
        lbl.text = " "
        lbl.textColor = TRPAppearanceSettings.Butterfly.topLabelTextColor
        lbl.font = TRPAppearanceSettings.Butterfly.topLabelFont
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    
    lazy var mainImage: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.darkGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 6
        return imageView
    }()
    
    lazy var matchRateContainer: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = TRPAppearanceSettings.Butterfly.matchRateBGColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = 2
        return containerView
    }()
    
    lazy var matchRateLbl: UILabel = {
        let lbl = UILabel()
        lbl.text = ""
        lbl.font = TRPAppearanceSettings.Butterfly.matchRateFont
        lbl.textColor = TRPAppearanceSettings.Butterfly.matchRateTextColor
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private lazy var topLabel: UILabel = {
        let lbl = UILabel(frame: .zero)
        lbl.text = ""
        lbl.textColor = TRPAppearanceSettings.Butterfly.topLabelTextColor
        lbl.font = TRPAppearanceSettings.Butterfly.topLabelFont
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    lazy var placeTitle: UILabel = {
        let lbl = UILabel(frame: .zero)
        lbl.text = ""
        lbl.textColor = TRPAppearanceSettings.Butterfly.placeNameTextColor
        lbl.font = TRPAppearanceSettings.Butterfly.placeNameTextFont
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.numberOfLines = 1
        return lbl
    }()
    
    internal lazy var subLabel: UILabel = {
        let lbl = UILabel(frame: .zero)
        lbl.text = ""
        lbl.textColor = TRPAppearanceSettings.Butterfly.subLabelTextColor
        lbl.font = TRPAppearanceSettings.Butterfly.subLabelFont
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    lazy var horizontalStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = NSLayoutConstraint.Axis.vertical
        stack.alignment = UIStackView.Alignment.leading
        stack.spacing = 6
        return stack
    }()
    
    lazy var thumbsUpBtn: UIButton = {
        let btn = UIButton()
        if let image = TRPImageController().getImage(inFramework: "thumbsup", inApp: TRPAppearanceSettings.Butterfly.thumbsUpImage) {
            btn.setImage(image, for: UIControl.State.normal)
            btn.imageView?.contentMode = .scaleAspectFit
        }
        btn.addTarget(self, action: #selector(thumbsUpBtnPressed), for: UIControl.Event.touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    lazy var thumbsDownBtn: UIButton = {
        let btn = UIButton()
        if let image = TRPImageController().getImage(inFramework: "thumbsup", inApp: TRPAppearanceSettings.Butterfly.thumbsUpImage) {
            btn.setImage(image, for: UIControl.State.normal)
            if let btnImage = btn.imageView {
                btnImage.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            }
            btn.imageView?.contentMode = .scaleAspectFit
        }
        btn.addTarget(self, action: #selector(thumbsDownBtnPressed), for: UIControl.Event.touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    lazy var thumbsUpGreenBtn: UIButton = {
        let btn = UIButton()
        if let image = TRPImageController().getImage(inFramework: "thumbsupgreen", inApp: TRPAppearanceSettings.Butterfly.thumbsUpGreenImage) {
            btn.setImage(image, for: UIControl.State.normal)
            btn.imageView?.contentMode = .scaleAspectFit
        }
        btn.addTarget(self, action: #selector(thumbsUpGreenBtnPressed), for: UIControl.Event.touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    public var starReviewPriceView: StarReviewPrice?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setupCustomView(stackView: UIStackView) {}
    
    override func prepareForReuse() {
        switchThumbsButton(type: .noSelect)
    }
    
    func switchThumbsButton(type: ThumbsType) {
        let showThumbsUpSelected = type == .upSelected ? true: false
        thumbsUpBtn.isHidden = showThumbsUpSelected
        thumbsUpBtn.alpha = showThumbsUpSelected ? 0 : 1
        thumbsDownBtn.isHidden = showThumbsUpSelected
        thumbsDownBtn.alpha = showThumbsUpSelected ? 0 : 1
        thumbsUpGreenBtn.isHidden = !showThumbsUpSelected
        thumbsUpGreenBtn.alpha = showThumbsUpSelected ? 1 : 0
    }
    
    
    public func setTopAndSubLabel(topContent: String?, subContent: String?) {
        //removeInStack(horizontalStackView)
        if let topContent = topContent {
            topLabel.text = topContent
        }else {
            topLabel.text = nil
        }
        if let subContent = subContent {
            subLabel.text = subContent
        }else {
            subLabel.text = nil
        }
        
    }
    
    public func setTopLabel(text: String) {
        topLabel.text = text
    }
    
    public func setSubLabel(text: String) {
           subLabel.text = text
       }
    
    private func removeInStack(_ stack: UIStackView) {
        for child in stack.arrangedSubviews {
            stack.removeArrangedSubview(child)
        }
    }

}

//MARK: - SETUP UIVIEW
extension ButterflyHorizontalCardCell {
    
    private func setupSubViews() {
        contentView.addSubview(dayInfoLabel)
        contentView.addSubview(mainImage)
        contentView.addSubview(horizontalStackView)
        
        contentView.addSubview(thumbsUpBtn)
        contentView.addSubview(thumbsDownBtn)
        contentView.addSubview(thumbsDownBtn)
        contentView.addSubview(thumbsUpGreenBtn)
        mainImage.addSubview(matchRateContainer)
        matchRateContainer.addSubview(matchRateLbl)
        thumbsUpGreenBtn.alpha = 0
        thumbsUpGreenBtn.isHidden = true
        
        horizontalStackView.addArrangedSubview(topLabel)
        horizontalStackView.addArrangedSubview(placeTitle)
        horizontalStackView.addArrangedSubview(subLabel)
        
        let constraint = [
            
            dayInfoLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            dayInfoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dayInfoLabel.heightAnchor.constraint(equalToConstant: 12),
            
            mainImage.topAnchor.constraint(equalTo: dayInfoLabel.bottomAnchor, constant: 8),
            mainImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainImage.heightAnchor.constraint(equalToConstant: mainImageHeight),
            
            horizontalStackView.topAnchor.constraint(equalTo: mainImage.bottomAnchor, constant: 12),
            horizontalStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            horizontalStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            
            thumbsUpBtn.widthAnchor.constraint(equalToConstant: 60),
            thumbsUpBtn.heightAnchor.constraint(equalToConstant: 30),
            thumbsUpBtn.topAnchor.constraint(equalTo: horizontalStackView.bottomAnchor, constant: 10),
            thumbsUpBtn.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -30),
            
            thumbsDownBtn.widthAnchor.constraint(equalToConstant: 60),
            thumbsDownBtn.heightAnchor.constraint(equalToConstant: 30),
            thumbsDownBtn.topAnchor.constraint(equalTo: horizontalStackView.bottomAnchor, constant: 10),
            thumbsDownBtn.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 30),
            
            thumbsUpGreenBtn.widthAnchor.constraint(equalToConstant: 60),
            thumbsUpGreenBtn.heightAnchor.constraint(equalToConstant: 30),
            thumbsUpGreenBtn.topAnchor.constraint(equalTo: horizontalStackView.bottomAnchor, constant: 10),
            thumbsUpGreenBtn.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 0),
            
            matchRateContainer.leadingAnchor.constraint(equalTo: mainImage.leadingAnchor, constant: 10),
            matchRateContainer.topAnchor.constraint(equalTo: mainImage.topAnchor, constant: 10),
            matchRateContainer.widthAnchor.constraint(equalToConstant: 85),
            matchRateContainer.heightAnchor.constraint(equalToConstant: 24),
            
            matchRateLbl.leadingAnchor.constraint(equalTo: matchRateContainer.leadingAnchor, constant: 0),
            matchRateLbl.topAnchor.constraint(equalTo: matchRateContainer.topAnchor, constant: 0),
            matchRateLbl.widthAnchor.constraint(equalTo: matchRateContainer.widthAnchor),
            matchRateLbl.centerYAnchor.constraint(equalTo: matchRateContainer.centerYAnchor, constant: 0),
            
           // contentView.bottomAnchor.constraint(equalTo: thumbsUpGreenBtn.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraint)
        setupCustomView(stackView: horizontalStackView)
        addRatingAndStarView()
    }
    
}

extension ButterflyHorizontalCardCell {
    
    func addRatingAndStarView() {
        if let starReviewCount = StarReviewPrice(frame: CGRect.zero,
                                                 starCount: 3.6,
                                                 ratingCount: 250,
                                                 price: 3) {
            starReviewCount.start()
            starReviewCount.translatesAutoresizingMaskIntoConstraints = false
            starReviewCount.heightAnchor.constraint(equalToConstant: 14).isActive = true
            starReviewCount.widthAnchor.constraint(equalToConstant: 140).isActive = true
            horizontalStackView.addArrangedSubview(starReviewCount)
            starReviewPriceView = starReviewCount
        }
    }
    
    func setStarRating(star: Float, rating: Int, price: Int) {
        guard let starViewer = starReviewPriceView else {return}
        let formattedStar = String(format: "%.01f", star)
        starViewer.starRateLbl.text =  "\(formattedStar)"
        starViewer.ratingCountLbl.text = "(\(rating))"
        if price != 0 {
            starViewer.setStartCount(price)
        }else {
            starViewer.isHiddenPriceLabel = true
        }
    }
    
}




//MARK: - CARDCELL BUTTON LISTENERS
extension ButterflyHorizontalCardCell {
    
    @objc func thumbsUpBtnPressed() {
        thumbsUpPressedHandler?(.noSelect)
    }
    
    @objc func thumbsDownBtnPressed() {
        thumbsDownPressedHandler?()
    }
    
    @objc func thumbsUpGreenBtnPressed() {
        thumbsUpPressedHandler?(.upSelected)
    }
    
    public func selectedAnimationFor(type: ThumbsType) {
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            var alpha: CGFloat = 0
            var status = true
            if type == .upSelected {
                alpha = 1
                status = false
            }
            self.thumbsUpBtn.isHidden = status
            self.thumbsDownBtn.isHidden = status
            self.thumbsUpBtn.alpha = alpha
            self.thumbsDownBtn.alpha = alpha
        }) { (_) in
            var alpha: CGFloat = 0
            var status = true
            if type == .upSelected {
                alpha = 1
                status = false
            }
            self.thumbsUpBtn.alpha = alpha
            self.thumbsDownBtn.alpha = alpha
            self.thumbsUpBtn.isHidden = status
            self.thumbsDownBtn.isHidden = status
        }
        
        UIView.animate(withDuration: 0.3, delay: 0.4, options: .curveEaseOut, animations: {
            var alpha: CGFloat = 0
            var status = true
            if type == .noSelect {
                alpha = 1
                status = false
            }
            self.thumbsUpGreenBtn.alpha = alpha
            self.thumbsUpGreenBtn.isHidden = status
        }) { (_) in
            var alpha: CGFloat = 0
            var status = true
            if type == .noSelect {
                alpha = 1
                status = false
            }
            self.thumbsUpGreenBtn.alpha = alpha
            self.thumbsUpGreenBtn.isHidden = status
        }
    }
}
