//
//  ButtonTableViewCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 13.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit
import TRPUIKit
final class ButtonTableViewCell: UITableViewCell {
    
    var buttonHeight: CGFloat = 30
    var buttonWidth: CGFloat = 200
    var buttonBgColor: UIColor = TRPColor.pink
    var action: (()-> Void)?
    
    
    public lazy var button: UIButton = {
        let btn = UIButton()
        btn.setTitle("Press Me", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.layer.cornerRadius = buttonHeight / 2
        btn.backgroundColor = buttonBgColor
        btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        return btn
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isHidden = true
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @objc func buttonPressed() {
        action?()
    }
}

//MARK: - UI Design
extension ButtonTableViewCell {
    
    fileprivate func setup() {
        self.selectionStyle = .none
        setButton()
    }
   
    private func setButton() {
        addSubview(button)
        button.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
        button.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        button.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        button.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
    }
    
}
