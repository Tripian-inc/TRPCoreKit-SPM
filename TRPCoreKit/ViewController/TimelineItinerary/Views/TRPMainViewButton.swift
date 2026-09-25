//
//  TRPMainViewButton.swift
//  TRPCoreKit
//
//  Created by Claude on 13.03.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit

/// Returns to overview camera; shown when: map mode + multiple cities + marker focused.
class TRPMainViewButton: UIButton {

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }

    // MARK: - Setup

    private func setupButton() {
        translatesAutoresizingMaskIntoConstraints = false

        backgroundColor = .white
        setTitleColor(ColorSet.fg.uiColor, for: .normal)
        titleLabel?.font = FontSet.montserratMedium.font(16)

        let title = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.mapMainView)
        setTitle(title, for: .normal)

        layer.cornerRadius = 16

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
        layer.masksToBounds = false

        heightAnchor.constraint(equalToConstant: 32).isActive = true
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    // MARK: - Animations

    func showAnimated() {
        guard isHidden else { return }
        isHidden = false
        alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }

    func hideAnimated() {
        guard !isHidden else { return }
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.isHidden = true
            self.alpha = 1
        })
    }
}
