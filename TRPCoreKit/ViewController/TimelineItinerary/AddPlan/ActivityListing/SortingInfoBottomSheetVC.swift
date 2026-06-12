//
//  SortingInfoBottomSheetVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import UIKit

class SortingInfoBottomSheetVC: TRPBaseUIViewController, DynamicHeightPresentable {
    var preferredContentHeight: CGFloat = 150
    

    // MARK: - Properties
    private let titleText: String
    private let messageText: String

    // MARK: - UI Components
    private lazy var headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.fg.uiColor
        label.textAlignment = .center
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TRPImageController().getImage(inFramework: "ic_close", inApp: nil), for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratRegular.font(16)
        label.textColor = ColorSet.fgWeak.uiColor
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Initialization
    init(title: String, message: String) {
        self.titleText = title
        self.messageText = message
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureContent()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)
        view.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            messageLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func configureContent() {
        titleLabel.text = titleText
        messageLabel.text = messageText
    }

    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
