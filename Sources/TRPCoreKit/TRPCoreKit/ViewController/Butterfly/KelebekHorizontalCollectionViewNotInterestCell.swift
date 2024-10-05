//
//  KelebekHorizontalCollectionViewNotInterestCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 29.01.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
class KelebekHorizontalCollectionViewNotInterestCell: UICollectionViewCell {
    
    var undoPressedHandler: (() -> Void)?
    var tellUsWhyPressedHandler: (() -> Void)?
    var removeCellPressedHandler: (() -> Void)?
    
    private lazy var verticalStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .equalSpacing
        stack.alignment = .center
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var undoButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("Undo", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(UIColor.darkGray, for: UIControl.State.normal)
        btn.addTarget(self, action: #selector(undoPressed), for: .touchUpInside)
        return btn
    }()
    
    private lazy var tellUsWhyButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("Tell us why", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(UIColor.darkGray, for: UIControl.State.normal)
        btn.addTarget(self, action: #selector(tellUsWhyPressed), for: .touchUpInside)
        return btn
    }()
    
    private lazy var removeCellButton: UIButton = {
        let btn = UIButton()
        if let image = TRPImageController().getImage(inFramework: "close_with_circle", inApp: TRPAppearanceSettings.Common.closeButtonImage) {
            btn.setImage(image, for: .normal)
        }
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(UIColor.darkGray, for: UIControl.State.normal)
        btn.addTarget(self, action: #selector(removeCellPressed), for: .touchUpInside)
        return btn
    }()
    
    private lazy var containerV: UIView = {
        let container = UIView()
        container.backgroundColor = UIColor(red: 240/255,
                                            green: 240/255,
                                            blue: 240/255,
                                            alpha: 1)
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.15
        container.layer.shadowOffset = .zero
        container.layer.shadowRadius = 3
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.cornerRadius = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()
    
    func setupCollectionView() {
        contentView.addSubview(containerV)
        containerV.addSubview(verticalStackView)
        
        //ContainerView position
        containerV.widthAnchor.constraint(equalToConstant: TRPAppearanceSettings.Butterfly.collectionCellWidth ).isActive = true
        containerV.heightAnchor.constraint(equalToConstant: TRPAppearanceSettings.Butterfly.collectionCellHeight - 20).isActive = true
        containerV.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        containerV.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        //Stackview position
        verticalStackView.centerXAnchor.constraint(equalTo: containerV.centerXAnchor).isActive = true
        verticalStackView.centerYAnchor.constraint(equalTo: containerV.centerYAnchor).isActive = true
        verticalStackView.widthAnchor.constraint(equalTo: containerV.widthAnchor).isActive = true
        verticalStackView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        verticalStackView.addArrangedSubview(undoButton)
        verticalStackView.addArrangedSubview(tellUsWhyButton)
        
        contentView.addSubview(removeCellButton)
        removeCellButton.trailingAnchor.constraint(equalTo: containerV.trailingAnchor, constant: -8).isActive = true
        removeCellButton.topAnchor.constraint(equalTo: containerV.topAnchor, constant: 8).isActive = true
    }
    
    @objc func undoPressed() {
        undoPressedHandler?()
    }
    
    @objc func tellUsWhyPressed() {
        tellUsWhyPressedHandler?()
    }

    @objc func removeCellPressed() {
        removeCellPressedHandler?()
    }
}
