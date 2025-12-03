//
//  TRPTimelineDayFilterView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 02.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit

public protocol TRPTimelineDayFilterViewDelegate: AnyObject {
    func dayFilterViewDidSelectDay(_ view: TRPTimelineDayFilterView, dayIndex: Int)
    func dayFilterViewDidTapFilter(_ view: TRPTimelineDayFilterView)
}

public class TRPTimelineDayFilterView: UIView {
    
    // MARK: - Properties
    public weak var delegate: TRPTimelineDayFilterViewDelegate?
    private var days: [String] = []
    private var selectedDayIndex: Int = 0
    
    // MARK: - UI Components
    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Load custom calendar icon
        let calendarIcon = TRPImageController().getImage(inFramework: "ic_calendar", inApp: nil)
        button.setImage(calendarIcon, for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        
        // Light gray circular background with subtle outer ring
        button.backgroundColor = ColorSet.neutral100.uiColor
        button.layer.cornerRadius = 22
        button.clipsToBounds = false
        
        // Add subtle shadow/border effect for the outer ring
        button.layer.borderWidth = 1
        button.layer.borderColor = ColorSet.neutral200.uiColor.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.05
        button.layer.shadowRadius = 2
        
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.estimatedItemSize = CGSize(width: 150, height: 44)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 16)
        
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
        backgroundColor = .white
        
        addSubview(filterButton)
        addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            // Filter Button
            filterButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            filterButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            filterButton.widthAnchor.constraint(equalToConstant: 44),
            filterButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Collection View
            collectionView.leadingAnchor.constraint(equalTo: filterButton.trailingAnchor, constant: 0),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func filterButtonTapped() {
        delegate?.dayFilterViewDidTapFilter(self)
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
            contentView.backgroundColor = UIColor.clear // Clear background
            contentView.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
            label.textColor = ColorSet.lineWeak.uiColor
        }
    }
}

