//
//  TRPActivityPriceRowView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 30.07.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit

/// Single source of truth for how an activity price is rendered across the timeline cells, the
/// AddPlan listing and the POI-detail product cards.
///
/// A missing (`nil`) or non-positive value means the activity is **free** — the tour API omits the
/// price field for free products instead of sending zero.
enum TRPActivityPriceFormat {

    static func isFree(_ value: Double?) -> Bool {
        guard let value = value else { return true }
        return value <= 0
    }

    /// "From <price>" / "FREE" for the single-label card layouts.
    static func attributedText(value: Double?, currency: String?) -> NSAttributedString {
        guard let value = value, !isFree(value) else {
            return NSAttributedString(string: freeText, attributes: valueAttributes)
        }

        let text = NSMutableAttributedString(string: fromText + " ", attributes: fromAttributes)
        text.append(NSAttributedString(string: formattedPrice(value, currency: currency),
                                       attributes: valueAttributes))
        return text
    }

    static func formattedPrice(_ value: Double, currency: String?) -> String {
        return TRPCurrencyHelper.formatPrice(value, currency: currency ?? "EUR")
    }

    static var freeText: String {
        return CommonLocalizationKeys.localized(CommonLocalizationKeys.free)
    }

    static var fromText: String {
        return CommonLocalizationKeys.localized(CommonLocalizationKeys.from)
    }

    static var fromAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: FontSet.montserratMedium.font(14),
            .foregroundColor: ColorSet.primaryText.uiColor
        ]
    }

    static var valueAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: FontSet.montserratBold.font(16),
            .foregroundColor: ColorSet.primaryText.uiColor
        ]
    }
}

/// Trailing-aligned price row used by the timeline activity cells and recommendation steps.
/// Pin its width to the parent stack so the content lands on the row's right edge.
final class TRPActivityPriceRowView: UIView {

    private let fromLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    private let row: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        row.addArrangedSubview(fromLabel)
        row.addArrangedSubview(valueLabel)
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
        ])
    }

    func configure(with price: TRPSegmentActivityPrice?) {
        configure(value: price?.value, currency: price?.currency)
    }

    func configure(value: Double?, currency: String?) {
        guard let value = value, !TRPActivityPriceFormat.isFree(value) else {
            fromLabel.isHidden = true
            valueLabel.text = TRPActivityPriceFormat.freeText
            return
        }

        fromLabel.isHidden = false
        fromLabel.text = TRPActivityPriceFormat.fromText
        valueLabel.text = TRPActivityPriceFormat.formattedPrice(value, currency: currency)
    }
}
