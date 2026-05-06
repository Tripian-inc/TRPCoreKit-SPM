//
//  TRPTimelineDayFilterView.swift
//  TRPCoreKit
//
//  Created by Cem Caygoz on 02.12.2024.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import UIKit
import TRPRestKit

// MARK: - Data Model
fileprivate struct DayDisplayData {
    let dayLetter: String     // Single letter day abbreviation ("M", "T", etc.)
    let dayNumber: String     // Day number ("12", "5")
    let monthAbbrev: String   // 3-letter month abbreviation ("nov", "dec")
}

public protocol TRPTimelineDayFilterViewDelegate: AnyObject {
    func dayFilterViewDidSelectDay(_ view: TRPTimelineDayFilterView, dayIndex: Int)
}

public class TRPTimelineDayFilterView: UIView {

    /// Selection mode controlling how past dates behave.
    /// - timeline: past dates remain fully selectable and styled like other unselected days.
    /// - addPlan: past dates render greyed out and ignore taps.
    public enum Mode {
        case timeline
        case addPlan
    }

    // MARK: - Properties
    public weak var delegate: TRPTimelineDayFilterViewDelegate?
    private var days: [DayDisplayData] = []
    private var rawDates: [Date] = []
    private var selectedDayIndex: Int = 0
    private var mode: Mode = .timeline

    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 50, height: 66)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)

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
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Public Methods
    public func configure(with dates: [Date], selectedDay: Int, mode: Mode = .timeline) {
        self.mode = mode
        self.rawDates = dates
        self.days = formatDays(dates)
        self.selectedDayIndex = selectedDay
        collectionView.reloadData()

        // Scroll to selected day if needed
        if selectedDay < days.count {
            let indexPath = IndexPath(item: selectedDay, section: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            }
        }
    }

    // MARK: - Private Methods
    private func formatDays(_ dates: [Date]) -> [DayDisplayData] {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: TRPClient.getLanguage())

        return dates.map { date in
            dateFormatter.dateFormat = "EEEEE"
            let dayLetter = dateFormatter.string(from: date).uppercased()

            dateFormatter.dateFormat = "d"
            let dayNumber = dateFormatter.string(from: date)

            dateFormatter.dateFormat = "MMM"
            let monthAbbrev = dateFormatter.string(from: date).lowercased()

            return DayDisplayData(dayLetter: dayLetter, dayNumber: dayNumber, monthAbbrev: monthAbbrev)
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
        let isDisabled = (mode == .addPlan) && isPastIndex(indexPath.item)
        cell.configure(with: days[indexPath.item], isSelected: isSelected, isDisabled: isDisabled)
        return cell
    }

    private func isPastIndex(_ index: Int) -> Bool {
        guard index >= 0, index < rawDates.count else { return false }
        return rawDates[index].isPastDay()
    }
}

// MARK: - UICollectionViewDelegate
extension TRPTimelineDayFilterView: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if mode == .addPlan, isPastIndex(indexPath.item) {
            return false
        }
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedDayIndex = indexPath.item
        collectionView.reloadData()
        delegate?.dayFilterViewDidSelectDay(self, dayIndex: indexPath.item)
    }
}

// MARK: - Day Cell
class TRPTimelineDayCell: UICollectionViewCell {

    static let reuseIdentifier = "TRPTimelineDayCell"

    private let dayLetterLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    private let dayNumberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = FontSet.montserratBold.font(16)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    private let monthLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fg.uiColor
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
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
        contentView.layer.cornerRadius = 8

        let stack = UIStackView(arrangedSubviews: [dayLetterLabel, dayNumberLabel, monthLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 2

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
        ])
    }

    fileprivate func configure(with data: DayDisplayData, isSelected: Bool, isDisabled: Bool = false) {
        dayLetterLabel.text = data.dayLetter
        dayNumberLabel.text = data.dayNumber
        monthLabel.text = data.monthAbbrev

        if isDisabled {
            contentView.layer.borderWidth = 0
            contentView.layer.borderColor = nil
            dayLetterLabel.textColor = ColorSet.fgWeaker.uiColor
            dayNumberLabel.font = FontSet.montserratMedium.font(16)
            dayNumberLabel.textColor = ColorSet.fgWeaker.uiColor
            monthLabel.textColor = ColorSet.fgWeaker.uiColor
        } else if isSelected {
            contentView.layer.borderWidth = 2
            contentView.layer.borderColor = ColorSet.line.uiColor.cgColor
            dayLetterLabel.textColor = ColorSet.fg.uiColor
            dayNumberLabel.font = FontSet.montserratBold.font(16)
            dayNumberLabel.textColor = ColorSet.fg.uiColor
            monthLabel.textColor = ColorSet.fg.uiColor
        } else {
            contentView.layer.borderWidth = 0
            contentView.layer.borderColor = nil
            dayLetterLabel.textColor = ColorSet.fgWeaker.uiColor
            dayNumberLabel.font = FontSet.montserratMedium.font(16)
            dayNumberLabel.textColor = ColorSet.fg.uiColor
            monthLabel.textColor = ColorSet.fg.uiColor
        }

        contentView.backgroundColor = .white
    }
}
