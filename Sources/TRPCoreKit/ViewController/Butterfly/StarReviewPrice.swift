//
//  StarReviewPrice.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 27.01.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit
import TRPUIKit
class StarReviewPrice: UIView {
    @PriceIconWrapper
    private var dolarSignIcon = 0
    
    private lazy var starImage: UIImageView = {
        let imageView = UIImageView()
        if let image =  TRPImageController().getImage(inFramework: "star2", inApp: TRPAppearanceSettings.ListOfRouting.alternativeImage) {
            imageView.image = image
        }
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    public lazy var starRateLbl: UILabel = {
        let generaterLbl = UILabel()
        generaterLbl.text = "4.1"
        generaterLbl.textColor = .init(red: 242/255, green: 169/255, blue: 59/255, alpha: 1.0)
        generaterLbl.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        generaterLbl.translatesAutoresizingMaskIntoConstraints = false
        return generaterLbl
    }()
    
    public lazy var ratingCountLbl: UILabel = {
        let generaterLbl = UILabel()
        generaterLbl.text = "(123)"
        generaterLbl.textColor = UIColor(red: 73.0/255.0, green: 73.0/255.0, blue: 73.0/255.0, alpha: 1.0);
        generaterLbl.font = UIFont.systemFont(ofSize: 14)
        generaterLbl.translatesAutoresizingMaskIntoConstraints = false
        return generaterLbl
    }()
    
    private lazy var priceLbl: UILabel = {
        let generaterLbl = UILabel()
        generaterLbl.text = "$$$$"
        generaterLbl.textColor = UIColor(red: 73.0/255.0, green: 73.0/255.0, blue: 73.0/255.0, alpha: 1.0);
        generaterLbl.font = UIFont.systemFont(ofSize: 14)
        generaterLbl.translatesAutoresizingMaskIntoConstraints = false
        return generaterLbl
    }()
    
    private let starCount: Float
    private var ratingCount: Int?
    private var price: Int?
    
    public var isHiddenPriceLabel: Bool = false {
        didSet {
            priceLbl.isHidden = isHiddenPriceLabel
        }
    }
    
    init?(frame: CGRect, starCount: Float, ratingCount: Int?, price: Int?) {
        self.starCount = starCount
        self.ratingCount = ratingCount
        if let price = price {
            if 0 < price && price < 5 {
                self.price = price
            }else {
                return nil
            }
        }
        self.price = price
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func start() {
        setUI()
    }
    
    func setStartCount(_ value: Int) {
        dolarSignIcon = value
        priceLbl.attributedText = $dolarSignIcon.generateDolarSign()
        
    }
    
    
}


extension StarReviewPrice {
    
    private func setUI() {
        var leastView = setupStartImage()
        if ratingCount != nil {
            leastView = setupRatingCountLbl(leadingView: leastView)
        }
        if price != nil {
            leastView = setupPriceLbl(leadingView: leastView)
        }
    }
    
    private func setupStartImage() -> UIView {
        addSubview(starImage)
        starImage.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        starImage.topAnchor.constraint(equalTo: topAnchor).isActive = true
        starImage.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        addSubview(starRateLbl)
        starRateLbl.leadingAnchor.constraint(equalTo: starImage.trailingAnchor, constant: 4).isActive = true
        starRateLbl.topAnchor.constraint(equalTo: topAnchor).isActive = true
        starRateLbl.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        return starRateLbl
    }
    
    private func setupRatingCountLbl(leadingView: UIView) -> UIView {
        addSubview(ratingCountLbl)
        ratingCountLbl.leadingAnchor.constraint(equalTo: leadingView.trailingAnchor, constant: 4).isActive = true
        ratingCountLbl.topAnchor.constraint(equalTo: topAnchor).isActive = true
        ratingCountLbl.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        return ratingCountLbl
    }
    
    private func setupPriceLbl(leadingView: UIView) -> UIView {
        addSubview(priceLbl)
        priceLbl.leadingAnchor.constraint(equalTo: leadingView.trailingAnchor, constant: 4).isActive = true
        priceLbl.topAnchor.constraint(equalTo: topAnchor).isActive = true
        priceLbl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        return priceLbl
    }
    
}
