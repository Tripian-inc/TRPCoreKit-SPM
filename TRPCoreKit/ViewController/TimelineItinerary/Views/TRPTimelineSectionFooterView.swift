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
    private let horizontalLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.lineWeak.uiColor
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
        contentView.backgroundColor = .clear

        contentView.addSubview(horizontalLine)

        NSLayoutConstraint.activate([
            horizontalLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            horizontalLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            horizontalLine.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            horizontalLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
}

