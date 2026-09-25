//
//  TRPErrorBanner.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 31.07.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit

/// Bottom banner for error messages — the error counterpart of `TRPSuccessToast`.
/// Unlike the toast it never auto-dismisses; the user closes it with its close button.
public final class TRPErrorBanner {

    private static let animationDuration: TimeInterval = 0.3
    private static weak var visibleBanner: UIView?

    /// Show an error banner over the top view controller, replacing one already on screen.
    public static func show(message: String) {
        DispatchQueue.main.async {
            guard let host = UIApplication.getTopViewController() else { return }
            present(in: host.view, message: message)
        }
    }

    private static func present(in container: UIView, message: String) {
        visibleBanner?.removeFromSuperview()

        let card = makeCard()
        let label = makeLabel(message: message)
        let closeButton = makeCloseButton()

        closeButton.addAction(UIAction { [weak card] _ in
            guard let card = card else { return }
            dismiss(card)
        }, for: .touchUpInside)

        card.addSubview(label)
        card.addSubview(closeButton)
        container.addSubview(card)
        visibleBanner = card

        card.alpha = 0
        card.transform = CGAffineTransform(translationX: 0, y: 24)

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            label.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -12),

            closeButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            closeButton.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseOut]) {
            card.alpha = 1
            card.transform = .identity
        }
    }

    private static func dismiss(_ card: UIView) {
        UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseIn]) {
            card.alpha = 0
            card.transform = CGAffineTransform(translationX: 0, y: 12)
        } completion: { _ in
            card.removeFromSuperview()
        }
    }

    private static func makeCard() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.errorBg.uiColor
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = ColorSet.errorIcon.uiColor.cgColor
        return view
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

    private static func makeCloseButton() -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let configuration = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: configuration), for: .normal)
        button.tintColor = ColorSet.fgWeak.uiColor
        return button
    }
}
