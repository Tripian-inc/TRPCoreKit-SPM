//
//  TRPSuccessToast.swift
//  TRPCoreKit
//
//  Lightweight bottom toast for success confirmations — white card with a green
//  check icon and a multi-line message. Slides up from the bottom edge of the
//  host VC's view, auto-dismisses with a fade after a configurable interval.
//
//  Created by Cem Çaygöz on 08.05.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit

public final class TRPSuccessToast {

    private static let displayDuration: TimeInterval = 3.5
    private static let animationDuration: TimeInterval = 0.3

    /// Show a success toast over `host`'s view. The toast is anchored to the bottom
    /// safe-area inset and dismisses automatically.
    public static func show(over host: UIViewController, message: String) {
        DispatchQueue.main.async {
            present(in: host.view, message: message)
        }
    }

    private static func present(in container: UIView, message: String) {
        let card = makeCard()
        let icon = makeIcon()
        let label = makeLabel(message: message)

        card.addSubview(icon)
        card.addSubview(label)
        container.addSubview(card)

        // Initial off-screen position for slide-up animation.
        card.alpha = 0
        card.transform = CGAffineTransform(translationX: 0, y: 24)

        NSLayoutConstraint.activate([
            // Card pinned to bottom with safe-area inset.
            card.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            // Icon — fixed 24×24 on the leading side, vertically aligned to the
            // first text baseline so multi-line messages still look balanced.
            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            icon.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),

            // Label fills the rest of the card.
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseOut]) {
            card.alpha = 1
            card.transform = .identity
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
                UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseIn]) {
                    card.alpha = 0
                    card.transform = CGAffineTransform(translationX: 0, y: 12)
                } completion: { _ in
                    card.removeFromSuperview()
                }
            }
        }
    }

    private static func makeCard() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.12
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        return view
    }

    private static func makeIcon() -> UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = ColorSet.greenAdvantage.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    private static func makeLabel(message: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = message
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fg.uiColor
        label.numberOfLines = 0
        return label
    }
}
