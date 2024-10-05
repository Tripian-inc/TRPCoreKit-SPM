//
//  ExplaineCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 9.06.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
class ExplaineCell: UITableViewCell {
 
    var closePressedHandler: (() -> Void)?
    
    public lazy var explaineLabel: UILabel = {
        let lbl = UILabel(frame: .zero)
        lbl.text = ""
        lbl.textColor = TRPAppearanceSettings.Butterfly.explaineTextColor
        lbl.font = TRPAppearanceSettings.Butterfly.explaineFont
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.numberOfLines = 0
        return lbl
    }()
    
    
    private lazy var closeButton: UIButton = {
        let btn = UIButton()
        if let image = TRPImageController().getImage(inFramework: "close_with_circle", inApp: TRPAppearanceSettings.Common.closeButtonImage) {
            let maskedImage = image.maskWithColor(color: UIColor.black)
            btn.setImage(maskedImage, for: .normal)
        }
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        return btn
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = TRPAppearanceSettings.Butterfly.explaineCellBg
        setupView ()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func closeButtonPressed() {
        closePressedHandler?()
    }
    
}

//MARK: - SetupUI
extension ExplaineCell {
    private func setupView (){
        contentView.addSubview(explaineLabel)
        contentView.addSubview(closeButton)
        let constraint = [
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            closeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            explaineLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            explaineLabel.trailingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: -16),
            explaineLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: explaineLabel.bottomAnchor, constant: 16)
        ]
        NSLayoutConstraint.activate(constraint)
        
    }
}
