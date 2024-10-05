//
//  ExperienceAvailabilityTableViewCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 1.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPUIKit
class ExperienceAvailabilityTableViewCell: UITableViewCell {
    
    let cornerRadius: CGFloat = 16
    var reservationAction: (() -> Void)?
    
    
    lazy var containerView: UIView = {
        var containerView = UIView()
        containerView.layer.borderWidth = 0.5
        containerView.layer.borderColor = UIColor.lightGray.cgColor
        containerView.layer.cornerRadius = self.cornerRadius
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.masksToBounds = true
        return containerView
    }()
    
    public var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0);
        label.text = ""
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    public var propertyStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    
    var bottomContainerView: UIView = {
        var containerView = UIView()
        containerView.backgroundColor = UIColor(red: 243/255, green: 243/255, blue: 243/255,alpha: 1)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()
    
    private lazy var priceLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = UIColor.black
        label.numberOfLines = 1
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    
    private lazy var priceExplaineLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.black
        label.numberOfLines = 1
        label.text = ""
        label.textAlignment = .left
        return label
    }()
    
    public lazy var reservationButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Select", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel!.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = TRPColor.pink
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        button.layer.cornerRadius = 20
        button.addTarget(self, action: #selector(reservationButtonPressed), for: .touchDown)
        return button
    }()
    private var selectedPeople: [ExperinceSelectedPeople] = []
    private var defaultPrice: String = "" {
        didSet {
            priceLabel.text = defaultPrice
        }
    }
    private var defaultPriceDescription = "" {
        didSet {
            priceExplaineLabel.text = defaultPriceDescription
        }
    }
    
    
    @objc func reservationButtonPressed() {
        reservationAction?()
    }
    
    public var discountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = TRPColor.darkGrey
        label.text = ""
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isHidden = true
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        
        addSubview(containerView)
        containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        containerView.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
        containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
        
        containerView.addSubview(titleLabel)
        titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16).isActive = true
        titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16).isActive = true
        
        containerView.addSubview(propertyStack)
        propertyStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16).isActive = true
        propertyStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16).isActive = true
        propertyStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16).isActive = true
        
        containerView.addSubview(bottomContainerView)
        bottomContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        bottomContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        bottomContainerView.topAnchor.constraint(equalTo: propertyStack.bottomAnchor, constant: 16).isActive = true
        bottomContainerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        bottomContainerView.heightAnchor.constraint(equalToConstant: 90).isActive = true
        
        bottomContainerView.addSubview(priceLabel)
        priceLabel.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: 24).isActive = true
        priceLabel.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor).isActive = true
        
        bottomContainerView.addSubview(priceExplaineLabel)
        priceExplaineLabel.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: 24).isActive = true
        priceExplaineLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 0).isActive = true
        
        bottomContainerView.addSubview(discountLabel)
        discountLabel.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: 24).isActive = true
        discountLabel.bottomAnchor.constraint(equalTo: priceLabel.topAnchor, constant: -4).isActive = true
        
        bottomContainerView.addSubview(reservationButton)
        reservationButton.trailingAnchor.constraint(equalTo: bottomContainerView.trailingAnchor, constant: -16).isActive = true
        reservationButton.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor).isActive = true
    }
    
    public func addProperty(title: String, property: String) {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = UIColor.black
        titleLabel.text = title
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subLabel = UILabel()
        subLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subLabel.textColor = UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0);
        subLabel.text = property
        subLabel.numberOfLines = 0
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        
        propertyStack.addArrangedSubview(titleLabel)
        propertyStack.addArrangedSubview(subLabel)
        propertyStack.setCustomSpacing(12, after: subLabel)
    }
    
    public func clearProperties() {
        for item in propertyStack.arrangedSubviews {
            propertyStack.removeArrangedSubview(item)
            item.removeFromSuperview()
        }
    }
    
    
    public func setPrice(price: String, description: String = "per person") {
        defaultPrice = price
        if defaultPriceDescription == "" {
            defaultPriceDescription = description
        }
    }
    
    public func setPeople(_ people: [ExperinceSelectedPeople]) {
        selectedPeople = people
        var count = 0
        selectedPeople.forEach { (person) in
            count += person.count
        }
        //TODO: GROUP
        defaultPriceDescription = "For \(count) person"
    }
    
    
}
