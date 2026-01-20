//
//  TRPTimelineDayFilterView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 02.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPRestKit

public protocol TRPTimelineDayFilterViewDelegate: AnyObject {
    func dayFilterViewDidSelectDay(_ view: TRPTimelineDayFilterView, dayIndex: Int)
}

public class TRPTimelineDayFilterView: UIView {
    
    // MARK: - Properties
    public weak var delegate: TRPTimelineDayFilterViewDelegate?
    private var days: [String] = []
    private var selectedDayIndex: Int = 0
    
    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.estimatedItemSize = CGSize(width: 150, height: 44)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.delegate = self
        collection.dataSource = self
        collection.register(TRPTimelineDayCell.self, forCellWithReuseIdentifier: TRPTimelineDayCell.reuseIdentifier)
        return collection
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    private func setupView() {
        backgroundColor = .clear
        
        addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            // Collection View
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Public Methods
    public func configure(with days: [String], selectedDay: Int) {
        self.days = days
        self.selectedDayIndex = selectedDay
        collectionView.reloadData()

        // Scroll to selected day if needed
        if selectedDay < days.count {
            let indexPath = IndexPath(item: selectedDay, section: 0)
            // Use a delay to ensure layout is complete before scrolling
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            }
        }
    }

    public func configure(with dates: [Date], selectedDay: Int) {
        let formattedDays = formatDays(dates)
        configure(with: formattedDays, selectedDay: selectedDay)
    }

    // MARK: - Private Methods
    private func formatDays(_ days: [Date]) -> [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: TRPClient.getLanguage())

        return days.map { date in
            dateFormatter.dateFormat = "EEEE"
            let dayName = dateFormatter.string(from: date).capitalized
            dateFormatter.dateFormat = "dd/MM"
            let dayDate = dateFormatter.string(from: date)
            return "\(dayName) \(dayDate)"
        }
    }
}

// MARK: - UICollectionViewDataSource
extension TRPTimelineDayFilterView: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TRPTimelineDayCell.reuseIdentifier, for: indexPath) as? TRPTimelineDayCell else {
            return UICollectionViewCell()
        }
        
        let isSelected = indexPath.item == selectedDayIndex
        cell.configure(with: days[indexPath.item], isSelected: isSelected)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension TRPTimelineDayFilterView: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedDayIndex = indexPath.item
        collectionView.reloadData()
        delegate?.dayFilterViewDidSelectDay(self, dayIndex: indexPath.item)
    }
}

// MARK: - Day Cell
class TRPTimelineDayCell: UICollectionViewCell {
    
    static let reuseIdentifier = "TRPTimelineDayCell"
    
    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = FontSet.montserratMedium.font(14)
        label.numberOfLines = 1
        label.lineBreakMode = .byClipping
        label.adjustsFontSizeToFitWidth = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        contentView.addSubview(label)
        contentView.layer.cornerRadius = 22
        contentView.layer.borderWidth = 1
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            label.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        layoutIfNeeded()
        
        // Calculate text width
        let text = label.text ?? ""
        let font = label.font ?? FontSet.montserratMedium.font(14)
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        
        // Return size with padding (16px on each side = 32px total)
        let totalWidth = ceil(textWidth) + 32
        return CGSize(width: max(totalWidth, 80), height: 44)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        
        let size = systemLayoutSizeFitting(
            layoutAttributes.size,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .required
        )
        
        var frame = layoutAttributes.frame
        frame.size.width = size.width
        frame.size.height = 44
        layoutAttributes.frame = frame
        
        return layoutAttributes
    }
    
    func configure(with day: String, isSelected: Bool) {
        label.text = day
        
        if isSelected {
            contentView.backgroundColor = ColorSet.bgPink.uiColor // Light pink background
            contentView.layer.borderColor = ColorSet.primary.uiColor.cgColor // Pink border
            label.textColor = ColorSet.primary.uiColor
        } else {
            contentView.backgroundColor = UIColor.white // Clear background
            contentView.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
            label.textColor = ColorSet.primaryWeakText.uiColor
        }
    }
}

