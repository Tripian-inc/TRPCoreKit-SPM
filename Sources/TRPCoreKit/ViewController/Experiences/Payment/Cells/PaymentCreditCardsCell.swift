//
//  PaymentCreditCardsCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-12-23.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit
import TRPProvider

class PaymentCreditCardsCell: UITableViewCell {

    
    lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.spacing = 12
        return stack
    }()
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupUI() {
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
        
        
    }
    
    public func setupCards(_ cards: [GYGCardType]) {
        
        if !stack.subviews.isEmpty {return}
        
        //TODO: BCMC EKSİK
        if cards.contains(.visa) {
            let visa = createCardIcon("payment_visa")
            stack.addArrangedSubview(visa)
        }
        
        if cards.contains(.masterCard) {
            let master = createCardIcon("payment_master")
            stack.addArrangedSubview(master)
        }
        
        if cards.contains(.jcb) {
            let jcb = createCardIcon("payment_jcb")
            stack.addArrangedSubview(jcb)
        }
        
        if cards.contains(.amex) {
            let amex = createCardIcon("payment_amex")
            stack.addArrangedSubview(amex)
        }
        
        if cards.contains(.discover) {
            let dicover = createCardIcon("payment_dicover")
            stack.addArrangedSubview(dicover)
        }
        
        let spacer = UIView()
        stack.addArrangedSubview(spacer)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }
    
    private func createCardIcon(_ name: String) -> UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 42).isActive = true
        imageView.image = TRPImageController().getImage(inFramework: name, inApp: nil)
        return imageView
    }

}
