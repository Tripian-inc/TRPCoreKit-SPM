//
//  TRPTimelineConflictWarningView.swift
//  TRPCoreKit
//
//  Warning banner shown when the selected day has time conflicts. Installed as
//  `tableView.tableHeaderView` by the host VC so it scrolls together with the
//  list contents. Colours match the conflict styling on `TRPTimelineTimeBadgeView`
//  (warningBg + warningBorder) for visual consistency.
//

import UIKit

final class TRPTimelineConflictWarningView: UIView {

    /// Fired when the user taps the close button. The host VC tears the banner
    /// down (so the dismissed state can be remembered at a higher level).
    var onCloseTapped: (() -> Void)?

    // MARK: - UI

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.warningBg.uiColor
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = ColorSet.warningBorder.uiColor.cgColor
        view.layer.masksToBounds = true
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ColorSet.warningBorder.uiColor
        imageView.image = TRPImageController()
            .getImage(inFramework: "ic_time", inApp: nil)?
            .withRenderingMode(.alwaysTemplate)
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fg.uiColor
        label.numberOfLines = 0
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = ColorSet.fg.uiColor
        let icon = TRPImageController()
            .getImage(inFramework: "ic_close", inApp: nil)?
            .withRenderingMode(.alwaysTemplate)
        button.setImage(icon, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear
        // Used as `tableView.tableHeaderView` — the host sets our frame
        // explicitly, so leave autoresizing translation ON. Inner subviews still
        // use Auto Layout (their TAMIC stays false).
        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [.flexibleWidth]

        addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(messageLabel)
        containerView.addSubview(closeButton)

        messageLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.conflictWarning)

        NSLayoutConstraint.activate([
            // Container: 16pt outer margin (matches the timeline list's
            // horizontal padding), 4/8 vertical breathing room.
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            // Icon: top:16, left:16 from container.
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            // Message: top/bottom:16; left from icon (8pt), right to close (8pt).
            messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            messageLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),

            // Close: top:16, right:16 from container.
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        onCloseTapped?()
    }
}
