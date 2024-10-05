//
//  TRPInputTableViewCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 1.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
class TRPInputTableViewCell: TRPBaseTableViewCell {
    
    var action: ((_ text: String) -> Void)?
    var beginEditingAction:((_ textField: UITextField) -> Void)?
    
    public var inputText: UITextField = {
        let input = UITextField()
        input.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        input.textColor = UIColor.black //UIColor(red: 73.0/255.0, green: 73.0/255.0, blue: 73.0/255.0, alpha: 1.0);
        input.placeholder = ""
        input.keyboardType = .numberPad
        input.translatesAutoresizingMaskIntoConstraints = false
        
        return input
    }()
    
    override func setupCustom(stack: UIStackView) {
        stack.addArrangedSubview(inputText)
        inputText.widthAnchor.constraint(equalToConstant: 280).isActive = true
        inputText.addTarget(self, action: #selector(inputTextDidChanged(_:)), for: .editingChanged)
        inputText.delegate = self
    }
    
    
    @objc func inputTextDidChanged(_ sender: UITextField) {
        action?(sender.text ?? "")
    }
    
}

extension TRPInputTableViewCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        beginEditingAction?(textField)
    }
}
