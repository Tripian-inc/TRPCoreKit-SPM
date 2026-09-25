//
//  TRPOnboardingVC.swift
//  TRPCoreKit
//
//  Created by Cem Caygoz on 25.03.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit

// MARK: - TRPOnboardingVC

public class TRPOnboardingVC: TRPBaseUIViewController, DynamicHeightPresentable {

    // MARK: - Constants
    private let headerHeight: CGFloat = 44
    private let headerTopPadding: CGFloat = 16
    private let footerHeight: CGFloat = 128 // Continue button + Skip button + spacing
    private let contentHeight: CGFloat = 480 // Header image + title + features + footer text

    // MARK: - Properties

    private let viewModel: TRPOnboardingViewModel

    /// Completion handler called when Continue button is tapped
    public var onContinue: (() -> Void)?

    /// Completion handler called when Skip or Close button is tapped
    public var onSkip: (() -> Void)?

    // MARK: - UI Components - Header
    private let headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TRPImageController().getImage(inFramework: "ic_close", inApp: nil), for: .normal)
        button.tintColor = ColorSet.primaryText.uiColor
        return button
    }()

    // MARK: - Content
//    private lazy var contentScrollView: UIScrollView = {
//        let scroll = UIScrollView()
//        scroll.translatesAutoresizingMaskIntoConstraints = false
//        scroll.showsVerticalScrollIndicator = false
//        scroll.alwaysBounceVertical = false
//        return scroll
//    }()

    private lazy var contentContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    private lazy var headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = TRPImageController().getImage(inFramework: "ic_onboarding", inApp: nil)
        return imageView
    }()

    private lazy var titleStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = viewModel.title
        label.font = FontSet.montserratBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        return label
    }()

    private lazy var betaBadge: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = viewModel.badgeText
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = ColorSet.bgPurple.uiColor
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()

    private lazy var featuresStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()

    private lazy var footerTextStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        return stack
    }()

    private lazy var footerLine1Label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = viewModel.footerLine1
        label.font = FontSet.montserratLight.font(14)
        label.textColor = ColorSet.fgWeak.uiColor
        label.textAlignment = .center
        return label
    }()

    private lazy var footerLine2Label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = viewModel.footerLine2
        label.font = FontSet.montserratLight.font(14)
        label.textColor = ColorSet.fgWeak.uiColor
        label.textAlignment = .center
        return label
    }()

    // MARK: - Footer (Sticky)
    private let footerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    private lazy var continueButton: TRPButton = {
        let button = TRPButton(title: viewModel.continueButtonTitle, style: .primary)
        return button
    }()

    private lazy var skipButton: TRPButton = {
        let button = TRPButton(title: viewModel.skipButtonTitle, style: .secondaryBold)
        return button
    }()

    // MARK: - DynamicHeightPresentable
    public var preferredContentHeight: CGFloat {
        return headerTopPadding + headerHeight + contentHeight + footerHeight
    }

    // MARK: - Initialization

    public init(viewModel: TRPOnboardingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Prevent dismissal by swiping - only buttons can dismiss
        isModalInPresentation = true
    }

    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white

        setupHeader()
        setupContent()
        setupFooter()
        setupActions()
    }

    // MARK: - Setup

    private func setupHeader() {
        view.addSubview(headerView)
        headerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            // Header View
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: headerTopPadding),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: headerHeight),

            // Close Button (right side only)
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupFooter() {
        view.addSubview(footerView)
        footerView.addSubview(continueButton)
        footerView.addSubview(skipButton)

        NSLayoutConstraint.activate([
            // Footer View
            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            footerView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor),
            footerView.topAnchor.constraint(equalTo: contentContainerView.bottomAnchor, constant: 24),

            // Continue Button
            continueButton.topAnchor.constraint(equalTo: footerView.topAnchor),
            continueButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
            continueButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),

            // Skip Button
            skipButton.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 16),
            skipButton.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            skipButton.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -8)
        ])
    }

    private func setupContent() {
//        view.addSubview(contentScrollView)
        view.addSubview(contentContainerView)

        // Add content elements
        contentContainerView.addSubview(headerImageView)
        contentContainerView.addSubview(titleStackView)
        contentContainerView.addSubview(featuresStackView)
        contentContainerView.addSubview(footerTextStackView)

        // Title stack
        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(betaBadge)

        // Features
        let feature1 = createFeatureRow(
            iconName: "ic_onboarding_route",
            title: viewModel.feature1Title,
            description: viewModel.feature1Description
        )
        let feature2 = createFeatureRow(
            iconName: "ic_onboarding_calendar",
            title: viewModel.feature2Title,
            description: viewModel.feature2Description
        )
        let feature3 = createFeatureRow(
            iconName: "ic_onboarding_heart",
            title: viewModel.feature3Title,
            description: viewModel.feature3Description
        )

        featuresStackView.addArrangedSubview(feature1)
        featuresStackView.addArrangedSubview(feature2)
        featuresStackView.addArrangedSubview(feature3)

        // Footer text
        footerTextStackView.addArrangedSubview(footerLine1Label)
        footerTextStackView.addArrangedSubview(footerLine2Label)

        // Badge padding
        betaBadge.setContentHuggingPriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            // ScrollView fills the space between header and footer
            contentContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            contentContainerView.bottomAnchor.constraint(equalTo: footerView.topAnchor),

            // Content container inside scroll view
//            contentContainerView.topAnchor.constraint(equalTo: contentScrollView.topAnchor),
//            contentContainerView.leadingAnchor.constraint(equalTo: contentScrollView.leadingAnchor),
//            contentContainerView.trailingAnchor.constraint(equalTo: contentScrollView.trailingAnchor),
//            contentContainerView.bottomAnchor.constraint(equalTo: contentScrollView.bottomAnchor),
//            contentContainerView.widthAnchor.constraint(equalTo: contentScrollView.widthAnchor),

            // Header image
            headerImageView.topAnchor.constraint(equalTo: contentContainerView.topAnchor, constant: 16),
            headerImageView.centerXAnchor.constraint(equalTo: contentContainerView.centerXAnchor),
            headerImageView.heightAnchor.constraint(equalToConstant: 148),
            headerImageView.widthAnchor.constraint(equalToConstant: 198),

            // Title stack
            titleStackView.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: 8),
            titleStackView.centerXAnchor.constraint(equalTo: contentContainerView.centerXAnchor),
            titleStackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentContainerView.leadingAnchor, constant: 24),
            titleStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentContainerView.trailingAnchor, constant: -24),

            // Beta badge padding
            betaBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 49),
            betaBadge.heightAnchor.constraint(equalToConstant: 24),

            // Features stack
            featuresStackView.topAnchor.constraint(equalTo: titleStackView.bottomAnchor, constant: 24),
            featuresStackView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 24),
            featuresStackView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor, constant: -24),

            // Footer text stack
            footerTextStackView.topAnchor.constraint(equalTo: featuresStackView.bottomAnchor, constant: 24),
            footerTextStackView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 24),
            footerTextStackView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor, constant: -24),
            footerTextStackView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor)
        ])
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
    }

    // MARK: - Helper Methods

    private func createFeatureRow(iconName: String, title: String, description: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.image = TRPImageController().getImage(inFramework: iconName, inApp: nil)

        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.numberOfLines = 0

        // Create attributed string with bold title and regular description
        let fullText = title + " " + description
        let attributedString = NSMutableAttributedString(string: fullText)

        // Title styling (bold)
        let titleRange = NSRange(location: 0, length: title.count)
        attributedString.addAttributes([
            .font: FontSet.montserratBold.font(14),
            .foregroundColor: ColorSet.primaryText.uiColor
        ], range: titleRange)

        // Description styling (regular)
        let descriptionRange = NSRange(location: title.count + 1, length: description.count)
        attributedString.addAttributes([
            .font: FontSet.montserratLight.font(14),
            .foregroundColor: ColorSet.primaryText.uiColor
        ], range: descriptionRange)

        textLabel.attributedText = attributedString

        containerView.addSubview(iconImageView)
        containerView.addSubview(textLabel)

        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 2),
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),

            textLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            textLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            textLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        return containerView
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() {
        viewModel.didTapDismiss()
    }

    @objc private func continueButtonTapped() {
        viewModel.didTapContinue()
    }

    @objc private func skipButtonTapped() {
        viewModel.didTapDismiss()
    }
}

// MARK: - TRPOnboardingViewModelDelegate

extension TRPOnboardingVC: TRPOnboardingViewModelDelegate {

    public func onboardingViewModel(shouldDismiss: Bool, wasSkipped: Bool) {
        if shouldDismiss {
            dismiss(animated: true) { [weak self] in
                if wasSkipped {
                    self?.onSkip?()
                } else {
                    self?.onContinue?()
                }
            }
        }
    }
}
