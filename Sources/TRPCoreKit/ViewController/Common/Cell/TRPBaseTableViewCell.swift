//
//  TRPBaseTableViewCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 1.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
class TRPBaseTableViewCell: UITableViewCell {
    
    private lazy var horizontalStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = NSLayoutConstraint.Axis.vertical
        stack.alignment = UIStackView.Alignment.leading
        stack.spacing = 12
        return stack
    }()
    
    public var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .light)
        label.textColor = UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0);
        label.text = "Title"
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isHidden = true
        setupHorizontalStack()
        setupCustom(stack: horizontalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal func setupHorizontalStack(){
        addSubview(horizontalStackView)
        horizontalStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        horizontalStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
        horizontalStackView.topAnchor.constraint(equalTo: topAnchor, constant: 20).isActive = true
        horizontalStackView.addArrangedSubview(titleLabel)
        bottomAnchor.constraint(equalTo: horizontalStackView.bottomAnchor, constant: 12).isActive = true
    }
    
    func setupCustom(stack: UIStackView) {}
    
}
