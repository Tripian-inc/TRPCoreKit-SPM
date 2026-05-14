//
//  TRPTimelineMapPOIPreviewCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 25.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit
import SDWebImage

class TRPTimelineMapPOIPreviewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "TRPTimelineMapPOIPreviewCell"
    
    // MARK: - UI Components
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private lazy var numberBadge: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 2
        view.layer.borderColor = ColorSet.fg.uiColor.cgColor
        return view
    }()
    
    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.fg.uiColor
        label.textAlignment = .center
        return label
    }()
    
    private lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.backgroundColor = ColorSet.neutral100.uiColor
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(14)
        label.textColor = ColorSet.fg.uiColor
        label.numberOfLines = 2
        return label
    }()

    private lazy var cityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.fgWeak.uiColor
        label.numberOfLines = 1
        return label
    }()

    private lazy var timeIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = TRPImageController().getImage(inFramework: "ic_time", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(13)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    private lazy var noLocationBadge: TRPPaddingLabel = {
        let label = TRPPaddingLabel(4, 4, 8, 8)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(10)
        label.textColor = ColorSet.infoIcon.uiColor
        label.backgroundColor = ColorSet.bgBlue.uiColor
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.noExactLocation)
        label.isHidden = true
        return label
    }()

    private lazy var timeRow: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.isHidden = true
        return stack
    }()

    private lazy var mainTextStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        contentView.addSubview(containerView)
        containerView.addSubview(thumbnailImageView)
        containerView.addSubview(numberBadge)  // Add badge after image so it's on top
        numberBadge.addSubview(numberLabel)
        containerView.addSubview(mainTextStack)

        // Time row: icon + label
        timeRow.addArrangedSubview(timeIcon)
        timeRow.addArrangedSubview(timeLabel)

        // Main vertical stack (city → title → noLocationBadge → time).
        // Each child collapses cleanly when hidden, so layout is correct whether
        // the badge or the time row is present.
        mainTextStack.addArrangedSubview(cityLabel)
        mainTextStack.addArrangedSubview(titleLabel)
        mainTextStack.addArrangedSubview(noLocationBadge)
        mainTextStack.addArrangedSubview(timeRow)

        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),

            // Thumbnail (102x102, corner radius 4, top/leading/bottom 12)
            thumbnailImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            thumbnailImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 102),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 102),

            // Number Badge (24x24, positioned relative to contentView)
            numberBadge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            numberBadge.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            numberBadge.widthAnchor.constraint(equalToConstant: 24),
            numberBadge.heightAnchor.constraint(equalToConstant: 24),

            // Number Label (18px semibold)
            numberLabel.centerXAnchor.constraint(equalTo: numberBadge.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: numberBadge.centerYAnchor),

            // Main text stack (city/title/badge/time)
            mainTextStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            mainTextStack.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 16),
            mainTextStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            mainTextStack.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12),

            // Time row icon size
            timeIcon.widthAnchor.constraint(equalToConstant: 16),
            timeIcon.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    // MARK: - Configuration
    func configure(with poi: TRPPoi, orderNumber: Int) {
        numberLabel.text = "\(orderNumber)"
        titleLabel.text = poi.name
        
        // Load image
        if let imageUrl = poi.image?.url, let url = URL(string: imageUrl) {
            thumbnailImageView.sd_setImage(with: url, placeholderImage: nil)
        } else {
            thumbnailImageView.image = nil
            thumbnailImageView.backgroundColor = ColorSet.neutral100.uiColor
        }
        
        // For POIs, we don't have specific date/time, so hide them
        timeRow.isHidden = true
    }

    func configure(with segment: TRPTimelineSegment, orderNumber: Int) {
        numberLabel.text = "\(orderNumber)"

        guard let additionalData = segment.additionalData else {
            titleLabel.text = segment.title ?? ""
            timeRow.isHidden = true
            return
        }

        titleLabel.text = additionalData.title ?? segment.title ?? ""

        // Configure image
        if let imageUrl = additionalData.imageUrl {
            thumbnailImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: nil)
        } else {
            thumbnailImageView.image = nil
            thumbnailImageView.backgroundColor = ColorSet.neutral100.uiColor
        }

        // Configure date and time (same style as TRPTimelineBookedActivityCell)
        if let startDatetime = additionalData.startDatetime {
            timeLabel.text = formatTime(from: startDatetime)
            timeRow.isHidden = false
        } else {
            timeRow.isHidden = true
        }
    }

    /// Configure cell with MapDisplayItem, unified order, and selection state
    func configure(with item: MapDisplayItem, order: Int, isSelected: Bool = false) {
        // Non-positive orders (e.g. flexible-time activities) render as "-" instead of a number.
        numberLabel.text = order > 0 ? "\(order)" : "-"
        titleLabel.text = item.title

        // Set city name
        cityLabel.text = item.cityName
        cityLabel.isHidden = item.cityName == nil

        // Update badge style based on selection state
        updateBadgeStyle(isSelected: isSelected)

        // No-exact-location tag (between title and time row)
        noLocationBadge.isHidden = !item.isNoLocation

        // Load image
        if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
            thumbnailImageView.sd_setImage(with: url, placeholderImage: nil)
        } else {
            thumbnailImageView.image = nil
            thumbnailImageView.backgroundColor = ColorSet.neutral100.uiColor
        }

        // Flexible-time activities show "Flexible" instead of a clock time.
        if item.isFlexibleActivity {
            timeLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.flexibleShort)
            timeRow.isHidden = false
        } else if let startTime = item.startTime {
            timeLabel.text = startTime
            timeRow.isHidden = false
        } else {
            timeRow.isHidden = true
        }
    }

    /// Update badge style based on selection state
    private func updateBadgeStyle(isSelected: Bool) {
        if isSelected {
            // Selected: Black background, white text, no border
            numberBadge.backgroundColor = ColorSet.fg.uiColor
            numberBadge.layer.borderWidth = 0
            numberLabel.textColor = .white
        } else {
            // Default: White background, black border, black text
            numberBadge.backgroundColor = .white
            numberBadge.layer.borderWidth = 2
            numberBadge.layer.borderColor = ColorSet.fg.uiColor.cgColor
            numberLabel.textColor = ColorSet.fg.uiColor
        }
    }
    
    private func formatTime(from dateString: String) -> String {
        guard let date = Date.fromString(dateString, format: "yyyy-MM-dd HH:mm:ss") else {
            return ""
        }
        return date.toString(format: "HH:mm") ?? ""
    }
    
    private func formatDate(from dateString: String) -> String {
        guard let date = Date.fromString(dateString, format: "yyyy-MM-dd HH:mm:ss") else {
            return ""
        }
        return date.toString(format: "dd/MM/yyyy") ?? ""
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        titleLabel.text = nil
        cityLabel.text = nil
        cityLabel.isHidden = true
        numberLabel.text = nil
        timeLabel.text = nil
        timeRow.isHidden = true
        noLocationBadge.isHidden = true
        // Reset badge to default (unselected) style
        updateBadgeStyle(isSelected: false)
    }
}

