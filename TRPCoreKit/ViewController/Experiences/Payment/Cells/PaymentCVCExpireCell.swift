//
//  PaymentCVCExpireCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-12-22.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
class PaymentCVCExpireCell: UITableViewCell {
    
    var mainStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = . fillEqually
        return stack
    }()
    
    public static let MMYYInputTag = 0
    public static let cvcInputTag = 1
    
    var action: ((_ input: String, _ tag: Int) -> Void)?
    
    
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
        
        mainStack.addArrangedSubview(expireStack())
        mainStack.addArrangedSubview(cvcStack())
    }
    
    private func expireStack() -> UIStackView {
        
        let title = UILabel()
        title.text = "MM/YY"
        title.font = UIFont.systemFont(ofSize: 15, weight: .light)
        title.textColor = UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0);
        
        let input = UITextField()
        input.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        input.placeholder = "MM/YY"
        input.tag = PaymentCVCExpireCell.MMYYInputTag
        input.addTarget(self, action: #selector(inputTextDidChanged(_:)), for: .editingChanged)
        input.keyboardType = .numberPad
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(input)
        
        return stack
    }
    
    private func cvcStack() -> UIStackView {
        
        let title = UILabel()
        title.text = "CVC"
        title.font = UIFont.systemFont(ofSize: 15, weight: .light)
        title.textColor = UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0);
        
        let input = UITextField()
        input.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        input.placeholder = "CVC"
        input.tag = PaymentCVCExpireCell.cvcInputTag
        input.addTarget(self, action: #selector(inputTextDidChanged(_:)), for: .editingChanged)
        input.keyboardType = .numberPad
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(input)
        
        return stack
    }
    
    
    @objc func inputTextDidChanged(_ sender: UITextField) {
        if sender.tag == PaymentCVCExpireCell.MMYYInputTag {
            sender.text = (sender.text ??  "").readableExpireDate()
        }
        action?(sender.text ?? "", sender.tag)
    }
    
    @objc func expireDateWillChanged(_ sender: UITextField) {
        
    }
    
}
