//
//  TRPPeopleCountTableViewCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 1.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
class TRPPeopleCountTableViewCell: UITableViewCell {
    
    public var adultTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .light)
        label.textColor = UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0);
        label.text = "Adult"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    public var childTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .light)
        label.textColor = UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0);
        label.text = "Child"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    public var adultInputText: UITextField = {
        let input = UITextField()
        input.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        input.textColor = UIColor.black //UIColor(red: 73.0/255.0, green: 73.0/255.0, blue: 73.0/255.0, alpha: 1.0);
        input.placeholder = "1"
        input.keyboardType = .numberPad
        input.translatesAutoresizingMaskIntoConstraints = false
        return input
    }()
    
    public var childInputText: UITextField = {
        let input = UITextField()
        input.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        input.textColor = UIColor.black //UIColor(red: 73.0/255.0, green: 73.0/255.0, blue: 73.0/255.0, alpha: 1.0);
        input.placeholder = "0"
        input.keyboardType = .numberPad
        input.translatesAutoresizingMaskIntoConstraints = false
        return input
    }()
    
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupUI(){
        addSubview(adultTitleLabel)
        addSubview(adultInputText)
        addSubview(childTitleLabel)
        addSubview(childInputText)
        
        let width = frame.width / 2 - 16
        
        let constraint = [
            adultTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            adultTitleLabel.widthAnchor.constraint(equalToConstant: width),
            adultTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            
            adultInputText.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            adultInputText.widthAnchor.constraint(equalToConstant: width),
            adultInputText.topAnchor.constraint(equalTo: adultTitleLabel.bottomAnchor, constant: 12),
            
            childTitleLabel.leadingAnchor.constraint(equalTo: adultTitleLabel.trailingAnchor),
            childTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            childTitleLabel.widthAnchor.constraint(equalToConstant: width),
            
            childInputText.leadingAnchor.constraint(equalTo: adultInputText.trailingAnchor),
            childInputText.widthAnchor.constraint(equalToConstant: width),
            childInputText.topAnchor.constraint(equalTo: adultTitleLabel.bottomAnchor, constant: 12),
            
            bottomAnchor.constraint(equalTo: adultInputText.bottomAnchor, constant: 12)
        ]
        NSLayoutConstraint.activate(constraint)
        
        contentView.isHidden = true
    }
    
}
