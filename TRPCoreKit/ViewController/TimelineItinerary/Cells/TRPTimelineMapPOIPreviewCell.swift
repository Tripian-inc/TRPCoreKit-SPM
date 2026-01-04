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
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private lazy var numberBadge: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.fg.uiColor
        view.layer.cornerRadius = 12
        return view
    }()
    
    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = .white
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
        label.numberOfLines = 3
        return label
    }()
    
    private lazy var dateIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = TRPImageController().getImage(inFramework: "ic_calendar", inApp: nil)
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratLight.font(14)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()
    
    private lazy var timeIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "clock")
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratLight.font(14)
        label.textColor = ColorSet.fg.uiColor
        return label
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
        containerView.addSubview(titleLabel)
        containerView.addSubview(dateIcon)
        containerView.addSubview(dateLabel)
        containerView.addSubview(timeIcon)
        containerView.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            
            // Thumbnail (80x80, corner radius 4, left/top/bottom 12)
            thumbnailImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            thumbnailImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 80),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Number Badge (24x24, positioned relative to contentView)
            numberBadge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            numberBadge.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            numberBadge.widthAnchor.constraint(equalToConstant: 24),
            numberBadge.heightAnchor.constraint(equalToConstant: 24),
            
            // Number Label (18px semibold)
            numberLabel.centerXAnchor.constraint(equalTo: numberBadge.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: numberBadge.centerYAnchor),
            
            // Title (14px semibold, top/right 12, left 16 from image)
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            titleLabel.heightAnchor.constraint(equalToConstant: 54),
            
            // Date Icon (below title, same as TRPTimelineBookedActivityCell style)
            dateIcon.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            dateIcon.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateIcon.widthAnchor.constraint(equalToConstant: 16),
            dateIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Date Label
            dateLabel.centerYAnchor.constraint(equalTo: dateIcon.centerYAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: dateIcon.trailingAnchor, constant: 6),
            
            // Time Icon (below date)
            timeIcon.topAnchor.constraint(equalTo: dateIcon.bottomAnchor, constant: 4),
            timeIcon.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            timeIcon.widthAnchor.constraint(equalToConstant: 16),
            timeIcon.heightAnchor.constraint(equalToConstant: 16),
            timeIcon.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12),
            
            // Time Label
            timeLabel.centerYAnchor.constraint(equalTo: timeIcon.centerYAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: timeIcon.trailingAnchor, constant: 6)
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
        dateIcon.isHidden = true
        dateLabel.isHidden = true
        timeIcon.isHidden = true
        timeLabel.isHidden = true
    }
    
    func configure(with segment: TRPTimelineSegment, orderNumber: Int) {
        numberLabel.text = "\(orderNumber)"

        guard let additionalData = segment.additionalData else {
            titleLabel.text = segment.title ?? ""
            dateIcon.isHidden = true
            dateLabel.isHidden = true
            timeIcon.isHidden = true
            timeLabel.isHidden = true
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
            dateLabel.text = formatDate(from: startDatetime)
            timeLabel.text = formatTime(from: startDatetime)
            dateIcon.isHidden = false
            dateLabel.isHidden = false
            timeIcon.isHidden = false
            timeLabel.isHidden = false
        } else {
            dateIcon.isHidden = true
            dateLabel.isHidden = true
            timeIcon.isHidden = true
            timeLabel.isHidden = true
        }
    }

    /// Configure cell with MapDisplayItem and unified order
    func configure(with item: MapDisplayItem, order: Int) {
        numberLabel.text = "\(order)"
        titleLabel.text = item.title

        // Load image
        if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
            thumbnailImageView.sd_setImage(with: url, placeholderImage: nil)
        } else {
            thumbnailImageView.image = nil
            thumbnailImageView.backgroundColor = ColorSet.neutral100.uiColor
        }

        // Show start time for all items (both POIs and activities)
        if let startTime = item.startTime {
            timeLabel.text = startTime
            timeIcon.isHidden = false
            timeLabel.isHidden = false
        } else {
            timeIcon.isHidden = true
            timeLabel.isHidden = true
        }

        // Hide date for map preview (only show time)
        dateIcon.isHidden = true
        dateLabel.isHidden = true
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
        numberLabel.text = nil
        dateLabel.text = nil
        timeLabel.text = nil
        dateIcon.isHidden = true
        dateLabel.isHidden = true
        timeIcon.isHidden = true
        timeLabel.isHidden = true
    }
}

