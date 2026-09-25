//
//  TRPTimelineSectionFooterView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 03.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit

class TRPTimelineSectionFooterView: UITableViewHeaderFooterView {

    static let reuseIdentifier = "TRPTimelineSectionFooterView"

    // MARK: - UI Components

    /// Separator between city sections: a top line + 10px neutral100 gap + bottom line.
    private let topLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.neutral200.uiColor
        return view
    }()

    private let bottomLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.neutral200.uiColor
        return view
    }()

    /// Fill between the two lines (the previous band colour, not transparent).
    private let gapFillView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.neutral100.uiColor
        return view
    }()

    // MARK: - Initialization
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupView() {
        // Transparent so the clear space above the divider matches the cells' (clear) bottom inset.
        contentView.backgroundColor = .clear

        contentView.addSubview(gapFillView)
        contentView.addSubview(topLine)
        contentView.addSubview(bottomLine)

        NSLayoutConstraint.activate([
            // 8px clear space above the divider. Combined with the last cell's 16px bottom inset,
            // the gap from the last item to the divider line totals 24px at a city-section boundary.
            topLine.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            topLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topLine.heightAnchor.constraint(equalToConstant: 0.5),

            // 10px neutral100 gap between the two lines.
            gapFillView.topAnchor.constraint(equalTo: topLine.bottomAnchor),
            gapFillView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gapFillView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gapFillView.heightAnchor.constraint(equalToConstant: 10),

            bottomLine.topAnchor.constraint(equalTo: gapFillView.bottomAnchor),
            bottomLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
}
