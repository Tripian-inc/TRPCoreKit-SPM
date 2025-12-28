//
//  TRPTimelineBookedActivityCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 02.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import SDWebImage

protocol TRPTimelineBookedActivityCellDelegate: AnyObject {
    func bookedActivityCellDidTapMoreOptions(_ cell: TRPTimelineBookedActivityCell)
}

class TRPTimelineBookedActivityCell: UITableViewCell {
    
    static let reuseIdentifier = "TRPTimelineBookedActivityCell"
    
    weak var delegate: TRPTimelineBookedActivityCellDelegate?
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fgGreen.uiColor
        label.textAlignment = .center
        label.backgroundColor = ColorSet.bgGreen.uiColor
        label.layer.cornerRadius = 16
        label.layer.borderColor = ColorSet.green250.uiColor.cgColor
        label.layer.borderWidth = 2
        label.clipsToBounds = true
        return label
    }()
    
    private let verticalLineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.lineWeak.uiColor
        return view
    }()
    
    private let activityImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.backgroundColor = ColorSet.neutral100.uiColor
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.fg.uiColor
        label.numberOfLines = 2
        return label
    }()
    
    private let confirmedBadge: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.fgGreen.uiColor
        label.backgroundColor = ColorSet.bgGreen.uiColor
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        // Text will be set dynamically in configure
        return label
    }()
    
    private let personIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = TRPImageController().getImage(inFramework: "ic_user", inApp: nil)
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let personLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratLight.font(14)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()
    
    private let cancellationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.greenAdvantage.uiColor
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupCell() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(timeLabel)
        contentView.addSubview(verticalLineView)
        contentView.addSubview(containerView)
        
        containerView.addSubview(activityImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(confirmedBadge)
        containerView.addSubview(personIcon)
        containerView.addSubview(personLabel)
        containerView.addSubview(cancellationLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Time Label
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeLabel.widthAnchor.constraint(equalToConstant: 120),
            timeLabel.heightAnchor.constraint(equalToConstant: 32),
            
            // Vertical Line
            verticalLineView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor),
            verticalLineView.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: 25),
            verticalLineView.widthAnchor.constraint(equalToConstant: 0.5),
            verticalLineView.bottomAnchor.constraint(equalTo: containerView.topAnchor),
            
            // Container View
            containerView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 24),
            containerView.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // Activity Image
            activityImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            activityImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            activityImageView.widthAnchor.constraint(equalToConstant: 80),
            activityImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Confirmed Badge
            confirmedBadge.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            confirmedBadge.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 12),
            confirmedBadge.widthAnchor.constraint(equalToConstant: 90),
            confirmedBadge.heightAnchor.constraint(equalToConstant: 24),
            
            // Person Icon
            personIcon.topAnchor.constraint(equalTo: confirmedBadge.bottomAnchor, constant: 8),
            personIcon.leadingAnchor.constraint(equalTo: confirmedBadge.leadingAnchor),
            personIcon.widthAnchor.constraint(equalToConstant: 16),
            personIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Person Label
            personLabel.centerYAnchor.constraint(equalTo: personIcon.centerYAnchor),
            personLabel.leadingAnchor.constraint(equalTo: personIcon.trailingAnchor, constant: 6),
            
            // Cancellation Label
            cancellationLabel.topAnchor.constraint(equalTo: personIcon.bottomAnchor, constant: 8),
            cancellationLabel.leadingAnchor.constraint(equalTo: confirmedBadge.leadingAnchor),
            cancellationLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
        ])
    }
    
    // MARK: - Configuration
    func configure(with segment: TRPTimelineSegment) {
        guard let additionalData = segment.additionalData else {
            return
        }

        // Use additionalData for all information
        titleLabel.text = additionalData.title ?? segment.title ?? ""

        // Configure badge based on segment type
        if segment.segmentType == .reservedActivity {
            // Reserved activity - show "Reservation" badge
            confirmedBadge.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.reservation)
            confirmedBadge.textColor = ColorSet.fgOrange.uiColor
            confirmedBadge.backgroundColor = ColorSet.bgOrange.uiColor
        } else {
            // Booked activity - show "Confirmed" badge
            confirmedBadge.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.confirmed)
            confirmedBadge.textColor = ColorSet.fgGreen.uiColor
            confirmedBadge.backgroundColor = ColorSet.bgGreen.uiColor
        }
        
        // Configure time from additionalData
        if let startDatetime = additionalData.startDatetime,
           let endDatetime = additionalData.endDatetime {
            let startTime = formatTime(from: startDatetime)
            let endTime = formatTime(from: endDatetime)
            timeLabel.text = "\(startTime) - \(endTime)"
        }
        
        // Configure person count from additionalData
        let adults = additionalData.adultCount
        let childrenCount = additionalData.childCount

        let adultsText = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.adults)

        if childrenCount > 0 {
            let childText = childrenCount == 1
                ? TimelineLocalizationKeys.localized(TimelineLocalizationKeys.child)
                : TimelineLocalizationKeys.localized(TimelineLocalizationKeys.children)
            personLabel.text = "\(adults) \(adultsText), \(childrenCount) \(childText)"
        } else {
            personLabel.text = "\(adults) \(adultsText)"
        }
        
        // Configure image from additionalData
        if let imageUrl = additionalData.imageUrl {
            activityImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: nil)
        }
        
        // Configure cancellation
        if let cancellation = additionalData.cancellation, !cancellation.isEmpty {
            cancellationLabel.text = cancellation
            cancellationLabel.isHidden = false
        } else {
            // Show default free cancellation text
            cancellationLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.freeCancellation)
            cancellationLabel.isHidden = false
        }
    }
    
    private func formatTime(from dateString: String) -> String {
        // Try format with seconds first, then without seconds
        let date = Date.fromString(dateString, format: "yyyy-MM-dd HH:mm:ss")
                   ?? Date.fromString(dateString, format: "yyyy-MM-dd HH:mm")

        guard let validDate = date else {
            return ""
        }
        return validDate.toString(format: "HH:mm") ?? ""
    }

    private func formatDate(from dateString: String) -> String {
        // Try format with seconds first, then without seconds
        let date = Date.fromString(dateString, format: "yyyy-MM-dd HH:mm:ss")
                   ?? Date.fromString(dateString, format: "yyyy-MM-dd HH:mm")

        guard let validDate = date else {
            return ""
        }
        return validDate.toString(format: "dd/MM/yyyy HH:mm") ?? ""
    }
}

