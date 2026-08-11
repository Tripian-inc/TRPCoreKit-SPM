//
//  TRPActivityRatingRowView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 30.07.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit

/// Rating + review-count row shared by the timeline activity cells and recommendation steps.
/// Hides itself when there is no rating, so it consumes no stack spacing.
final class TRPActivityRatingRowView: UIStackView {

    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratBold.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    private let starIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = TRPImageController().getImage(inFramework: "ic_rating_star", inApp: nil)
        imageView.tintColor = ColorSet.ratingStar.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let reviewLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratRegular.font(14)
        label.textColor = ColorSet.fgWeak.uiColor
        return label
    }()

    private let starSpacer = TRPActivityRatingRowView.spacer(width: 2)
    private let reviewSpacer = TRPActivityRatingRowView.spacer(width: 4)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
        spacing = 0
        alignment = .center
        isHidden = true

        addArrangedSubview(ratingLabel)
        addArrangedSubview(starSpacer)
        addArrangedSubview(starIcon)
        addArrangedSubview(reviewSpacer)
        addArrangedSubview(reviewLabel)

        NSLayoutConstraint.activate([
            starIcon.widthAnchor.constraint(equalToConstant: 14),
            starIcon.heightAnchor.constraint(equalToConstant: 14),
        ])
    }

    func configure(rating: Float?, ratingCount: Int?) {
        guard let rating = rating, rating > 0 || (ratingCount ?? 0) > 0 else {
            isHidden = true
            return
        }

        ratingLabel.text = String(format: "%.1f", rating).replacingOccurrences(of: ".", with: ",")

        if let ratingCount = ratingCount {
            let opinionsText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.opinions)
            reviewLabel.text = "\(ratingCount.formattedWithSeparator) \(opinionsText)"
            reviewLabel.isHidden = false
            reviewSpacer.isHidden = false
        } else {
            reviewLabel.isHidden = true
            reviewSpacer.isHidden = true
        }

        isHidden = false
    }

    private static func spacer(width: CGFloat) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: width).isActive = true
        return view
    }
}
