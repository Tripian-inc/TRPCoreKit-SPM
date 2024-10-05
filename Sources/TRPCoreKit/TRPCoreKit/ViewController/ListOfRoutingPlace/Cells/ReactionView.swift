//
//  ReactionView.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-11-17.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
import TRPUIKit
enum ReactionActionType {
    case thumbsDown, thumbsUp, replace, remove, undo
}

enum ReactionState {
    case none, unSelected, thumbsUp, thumbsDown
}

class ReactionView: UIView {
    
    var action: ((_ action: ReactionActionType) -> Void)?
    
    lazy var thumbsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = NSLayoutConstraint.Axis.horizontal
        stack.alignment = UIStackView.Alignment.trailing
        stack.spacing = 8;
        return stack
    }()
    
    lazy var thumbsUpBtn: UIButton = {
        let btn = UIButton()
        if let image = TRPImageController().getImage(inFramework: "thumbsup", inApp: TRPAppearanceSettings.Butterfly.thumbsUpImage) {
            btn.setImage(image, for: UIControl.State.normal)
            btn.imageView?.contentMode = .scaleAspectFit
        }
        btn.addTarget(self, action: #selector(thumbsUpBtnPressed), for: UIControl.Event.touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 28).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return btn
    }()
    
    lazy var thumbsDownBtn: UIButton = {
        let btn = UIButton()
        if let image = TRPImageController().getImage(inFramework: "thumbsdown", inApp: TRPAppearanceSettings.Butterfly.thumbsUpImage) {
            btn.setImage(image, for: UIControl.State.normal)
            btn.imageView?.contentMode = .scaleAspectFit
        }
        btn.addTarget(self, action: #selector(thumbsDownBtnPressed), for: UIControl.Event.touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 28).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return btn
    }()
    
    public lazy var replaceBtn: UIButton = {
        let btn = UIButton()
        let color = TRPColor.lightGrey
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(TRPColor.darkGrey, for: UIControl.State.normal)
        btn.addTarget(self, action: #selector(replaceButtonPressed), for: .touchUpInside)
        let alternativesText = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.step.thumbs.replace.title")
        btn.setTitle(" \(alternativesText) ", for: UIControl.State.normal)
        if let titleLabel = btn.titleLabel{
            titleLabel.font = UIFont.systemFont(ofSize: 9)
            titleLabel.textColor = UIColor.lightGray
        }
        btn.backgroundColor = .clear
        btn.layer.cornerRadius = 5
        btn.layer.borderWidth = 1
        btn.layer.borderColor = color.cgColor
        btn.heightAnchor.constraint(equalToConstant: 26).isActive = true
        btn.widthAnchor.constraint(equalToConstant: 100).isActive = true
        return btn
    }()
    
    public lazy var removeBtn: UIButton = {
        let btn = UIButton()
        let color = TRPColor.lightGrey
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(TRPColor.darkGrey, for: UIControl.State.normal)
        btn.addTarget(self, action: #selector(removeButtonPressed), for: .touchUpInside)
        let alternativesText = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.step.thumbs.remove")
        btn.setTitle(" \(alternativesText) ", for: UIControl.State.normal)
        if let titleLabel = btn.titleLabel{
            titleLabel.font = UIFont.systemFont(ofSize: 9)
            titleLabel.textColor = UIColor.lightGray
        }
        btn.backgroundColor = .clear
        btn.layer.cornerRadius = 5
        btn.layer.borderWidth = 1
        btn.layer.borderColor = color.cgColor
        btn.heightAnchor.constraint(equalToConstant: 26).isActive = true
        btn.widthAnchor.constraint(equalToConstant: 100).isActive = true
        return btn
    }()
    
    public var reactionState: ReactionState = .none {
        didSet {
            updateUI()
        }
    }
    
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(thumbsStackView)
        NSLayoutConstraint.activate([
            thumbsStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            thumbsStackView.topAnchor.constraint(equalTo: topAnchor),
            thumbsStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            thumbsStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        reactionState = .unSelected
    }
    
    @objc func thumbsUpBtnPressed() {
        if reactionState == .unSelected {
            reactionState = .thumbsUp
            action?(.thumbsUp)
        }else if reactionState == .thumbsUp {
            reactionState = .unSelected
            action?(.undo)
        }
    }
    
    @objc func thumbsDownBtnPressed() {
        if reactionState == .unSelected {
            reactionState = .thumbsDown
            action?(.thumbsDown)
        }else if reactionState == .thumbsDown {
            reactionState = .unSelected
            action?(.undo)
        }
    }
    
    @objc func replaceButtonPressed() {
        action?(.replace)
    }
    
    @objc func removeButtonPressed() {
        action?(.remove)
    }
}

extension ReactionView {
    
    func updateUI() {
        switch reactionState {
        case .none:
            clear()
        case .unSelected:
            setUnSelected();
        case .thumbsUp:
            setThumbsUp();
        case .thumbsDown:
            setThumbsDown();
        }
    }
    
    private func clear() {}
    
    private func setUnSelected() {
        removeButtonInStack(replaceBtn)
        removeButtonInStack(removeBtn)
        removeButtonInStack(thumbsUpBtn)
        removeButtonInStack(thumbsDownBtn)
        if !thumbsStackView.contains(thumbsUpBtn) {
            thumbsStackView.addArrangedSubview(thumbsUpBtn)
        }
        
        if !thumbsStackView.contains(thumbsDownBtn) {
            thumbsStackView.addArrangedSubview(thumbsDownBtn)
        }
        
        if let thumbsUpImage = TRPImageController().getImage(inFramework: "thumbsup", inApp: TRPAppearanceSettings.Butterfly.thumbsUpGreenImage),
           let thumbsDownImage = TRPImageController().getImage(inFramework: "thumbsdown", inApp: TRPAppearanceSettings.Butterfly.thumbsUpGreenImage){
            thumbsUpBtn.setImage(thumbsUpImage, for: UIControl.State.normal)
            thumbsDownBtn.setImage(thumbsDownImage, for: UIControl.State.normal)
        }
    }
    
    private func setThumbsUp() {
        if let image = TRPImageController().getImage(inFramework: "thumbsupgreen", inApp: TRPAppearanceSettings.Butterfly.thumbsUpGreenImage) {
            thumbsUpBtn.setImage(image, for: UIControl.State.normal)
        }
        removeButtonInStack(thumbsDownBtn)
    }
    
    private func setThumbsDown() {
        removeButtonInStack(thumbsUpBtn)
        removeButtonInStack(thumbsDownBtn)
        if !thumbsStackView.contains(replaceBtn) {
            thumbsStackView.addArrangedSubview(replaceBtn)
        }
        if !thumbsStackView.contains(removeBtn) {
            thumbsStackView.addArrangedSubview(removeBtn)
        }
        if let image = TRPImageController().getImage(inFramework: "thumbsdownred", inApp: TRPAppearanceSettings.Butterfly.thumbsUpGreenImage) {
            thumbsDownBtn.setImage(image, for: UIControl.State.normal)
        }
        if !thumbsStackView.contains(thumbsDownBtn) {
            thumbsStackView.addArrangedSubview(thumbsDownBtn)
        }
    }
    
    private func removeButtonInStack(_ btn: UIButton) {
        thumbsStackView.removeArrangedSubview(btn)
        btn.removeFromSuperview()
    }
}
