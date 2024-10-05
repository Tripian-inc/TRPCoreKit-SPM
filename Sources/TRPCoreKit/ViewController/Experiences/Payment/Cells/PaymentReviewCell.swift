//
//  PaymentReviewCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-12-21.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
class PaymentReviewCell: UITableViewCell {
    
    var mainStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = 16
        return stack
    }()
    
    lazy var tourTitle: UILabel = {
        var tourTitle = UILabel()
        tourTitle.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return tourTitle
    }()
    
    private var isAdded = false
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isHidden = true
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant:  -16)
        ])
        
    }
    
    
    public func configurate(_ model: PaymentReviewOrder) {
        if isAdded {return}
        isAdded.toggle()
        
        tourTitle.text = model.tourName
        let date = createSubStack(image: "payment_calendar", content: model.date)
        let info = createSubStack(image: "payment_info", content: model.optionInfo)
        let people = createSubStack(image: "payment_person", content: model.peopleInfo)
        let price = priceStack(model.totalPrice)
        
        mainStack.addArrangedSubview(tourTitle)
        mainStack.addArrangedSubview(date)
        mainStack.addArrangedSubview(info)
        mainStack.addArrangedSubview(people)
        mainStack.addArrangedSubview(price)
    }
    
    
    private func createSubStack(image: String?, content: String) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        let label = UILabel()
        label.text = content
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 2
        label.textColor = UIColor.darkGray
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        if let image = TRPImageController().getImage(inFramework: image, inApp: nil) {
            imageView.image = image
        }
        
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(label)
        imageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        return stack
    }
    
    private func priceStack(_ price: String) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        
        let total = UILabel()
        total.text = "Total"
        total.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        
        let label = UILabel()
        label.text = price
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        
        stack.addArrangedSubview(total)
        
        
        let spacer = UIView()
        stack.addArrangedSubview(spacer)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        stack.addArrangedSubview(label)
        
        return stack
    }
}
