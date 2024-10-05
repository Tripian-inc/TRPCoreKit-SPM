//
//  ProfileTextFieldCell.swift
//  TRPUserProfileKit
//
//  Created by Evren Yaşar on 16.09.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import UIKit


protocol ProfileTextFieldCellProtocol: AnyObject{
    func didTapCell()
    func setTextFieldVal(text: String, val: Int)
    func saveChanges()
}


class ProfileTextFieldCell: UITableViewCell {
    public var limitWith99 = false
    weak var cellDelegate: ProfileTextFieldCellProtocol?
    
    lazy var textField: UITextField = {
        let textField = UITextField(frame: CGRect.zero)
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.textColor = TRPColor.darkGrey
        textField.text = ""
        textField.delegate = self
        textField.placeholder = ""
        textField.addTarget(self,
                            action : #selector(textFieldDidChange(sender:)),
                            for : .editingChanged)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    lazy var textFieldPlaceholderLabel:UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = label.font.withSize(12)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.gray
        return label
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    private func setupViews() {
        contentView.isHidden = true
        addSubview(textField)
        textField.centerYAnchor.constraint(equalTo: bottomAnchor, constant: -20).isActive = true
        textField.heightAnchor.constraint(equalToConstant: 24).isActive = true
        textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20).isActive = true
        
        addSubview(textFieldPlaceholderLabel)
        textFieldPlaceholderLabel.bottomAnchor.constraint(equalTo:textField.topAnchor, constant:-10).isActive = true
        textFieldPlaceholderLabel.leadingAnchor.constraint(equalTo:leadingAnchor,constant: 20).isActive = true
        textFieldPlaceholderLabel.trailingAnchor.constraint(equalTo:trailingAnchor,constant: -20).isActive = true
    }
    
    fileprivate func showSaveButton(text: String, tag: Int){
        if text.count > 0 {
            self.cellDelegate?.didTapCell()
            self.cellDelegate?.setTextFieldVal(text: text, val: tag)
        }
    }
    
}

extension ProfileTextFieldCell: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        endEditing(true)
        if let text = textField.text{
            self.showSaveButton(text: text,tag: textField.tag)
            if textField.tag == 1 || textField.tag == 2 {
                if let nextField = textField.superview?.superview?.viewWithTag(textField.tag + 1) as? UITextField {
                    nextField.becomeFirstResponder()
                }
            }
            //            if textField.tag == 3 {
            //                self.cellDelegate?.saveChanges()
            //            }
        }
        return true
    }
    @objc func textFieldDidChange(sender: UITextField){
        if limitWith99 {
            if let input = sender.text, let number = Int(input) {
                var num = number
                if number > 99 {
                    num = 99
                }
                sender.text = "\(num)"
            }
        }
        
        if let text = textField.text{
            self.showSaveButton(text: text,tag: textField.tag)
        }
        
    }
}
