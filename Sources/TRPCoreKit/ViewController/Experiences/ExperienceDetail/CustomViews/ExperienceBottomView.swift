//
//  ExperienceBottomView.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 21.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit
import TRPUIKit


class ExperienceBottomView: UIView {

    
    lazy var contentView: UIView = {
        var view = UIView(frame: self.frame)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        //view.addSeparator(at: .top, color: .black, alpha: 0.2 , weight: 1, insets: .zero)
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: -1)
        view.layer.shadowRadius = 1
        
        return view
    }()

    private lazy var priceLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor.black
        label.numberOfLines = 1
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    
    public lazy var reservationButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Book now", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel!.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        button.backgroundColor = TRPColor.pink
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        button.layer.cornerRadius = 20
        return button
    }()
    
    private var discountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = TRPColor.darkGrey
        label.text = ""
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var priceLaberCenterY: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupView() {
        addSubview(contentView)
        addSubview(priceLabel)
        addSubview(reservationButton)
        addSubview(discountLabel)
        
        NSLayoutConstraint.activate([
            
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            reservationButton.widthAnchor.constraint(equalToConstant: 140),
            reservationButton.heightAnchor.constraint(equalToConstant: 40),
            reservationButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            reservationButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant:  -32),
            
            priceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            
            priceLabel.trailingAnchor.constraint(equalTo: reservationButton.leadingAnchor),
            
            discountLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            discountLabel.bottomAnchor.constraint(equalTo: priceLabel.topAnchor)
        ])
        
        priceLaberCenterY = priceLabel.centerYAnchor.constraint(equalTo: reservationButton.centerYAnchor, constant: 0)
        priceLaberCenterY!.isActive = true
    }
    
    public func setDiscount(savings: Double?) {
        
        
        if let value = savings, value != 0{
            discountLabel.text = "\(Int(value))% discount"
            priceLaberCenterY?.constant = 8
        }else {
            discountLabel.text = ""
        }
        layoutIfNeeded()
    }
    
    
    public func setPrice(price: String, description: String = "per person") {
        let attributed = price.addStyle([.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 20, weight: .bold)])
        attributed.addString(" " + description, syle: [.foregroundColor: TRPColor.darkGrey, .font: UIFont.systemFont(ofSize: 16, weight: .regular)])
        priceLabel.attributedText = attributed
    }
}
