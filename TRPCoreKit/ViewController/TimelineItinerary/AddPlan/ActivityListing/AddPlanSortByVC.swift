//
//  AddPlanSortByVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 06.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

// MARK: - Sort Option Model
public enum SortOption: Int, CaseIterable {
    case popularity = 0
    case rating
    case priceLowToHigh
//    case newest
    case durationShortToLong
    case durationLongToShort

    var title: String {
        switch self {
        case .popularity:
            return AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.sortPopularity)
        case .rating:
            return AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.sortRating)
        case .priceLowToHigh:
            return AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.sortPriceLowToHigh)
//        case .newest:
//            return AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.sortNewest)
        case .durationShortToLong:
            return AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.sortDurationShortToLong)
        case .durationLongToShort:
            return AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.sortDurationLongToShort)
        }
    }

    /// Returns (sortingBy, sortingType) tuple for API
    var apiParameters: (sortingBy: String, sortingType: String) {
        switch self {
        case .popularity:
            return ("score", "desc")
        case .rating:
            return ("rating", "desc")
        case .priceLowToHigh:
            return ("price", "asc")
//        case .newest:
//            return ("date", "desc")
        case .durationShortToLong:
            return ("duration", "asc")
        case .durationLongToShort:
            return ("duration", "desc")
        }
    }
}

// MARK: - AddPlanSortByVC
public class AddPlanSortByVC: UIViewController {

    // MARK: - Properties
    private var selectedOption: SortOption
    public var onSortOptionSelected: ((SortOption) -> Void)?

    // MARK: - UI Components
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.sortBy)
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(TRPImageController().getImage(inFramework: "ic_close", inApp: nil), for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    // MARK: - Initialization
    public init(selectedOption: SortOption = .popularity) {
        self.selectedOption = selectedOption
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)
        view.addSubview(tableView)

        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SortOptionCell.self, forCellReuseIdentifier: SortOptionCell.reuseIdentifier)

        NSLayoutConstraint.activate([
            // Header view
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            // Title label (centered)
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            // Close button (right side)
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),

            // Table view
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension AddPlanSortByVC: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SortOption.allCases.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SortOptionCell.reuseIdentifier, for: indexPath) as? SortOptionCell else {
            return UITableViewCell()
        }

        let option = SortOption.allCases[indexPath.row]
        let isSelected = option == selectedOption
        cell.configure(title: option.title, isSelected: isSelected)

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let option = SortOption.allCases[indexPath.row]
        selectedOption = option
        tableView.reloadData()

        // Notify and dismiss
        onSortOptionSelected?(option)
        dismiss(animated: true)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }
}

// MARK: - SortOptionCell
private class SortOptionCell: UITableViewCell {

    static let reuseIdentifier = "SortOptionCell"

    private let radioButton: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderWidth = 2
        view.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let radioInnerCircle: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.primary.uiColor
        view.layer.cornerRadius = 6
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratRegular.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = .white

        contentView.addSubview(radioButton)
        radioButton.addSubview(radioInnerCircle)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            // Radio button
            radioButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            radioButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            radioButton.widthAnchor.constraint(equalToConstant: 24),
            radioButton.heightAnchor.constraint(equalToConstant: 24),

            // Inner circle (centered in radio button)
            radioInnerCircle.centerXAnchor.constraint(equalTo: radioButton.centerXAnchor),
            radioInnerCircle.centerYAnchor.constraint(equalTo: radioButton.centerYAnchor),
            radioInnerCircle.widthAnchor.constraint(equalToConstant: 12),
            radioInnerCircle.heightAnchor.constraint(equalToConstant: 12),

            // Title label
            titleLabel.leadingAnchor.constraint(equalTo: radioButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title

        if isSelected {
            radioButton.layer.borderColor = ColorSet.primary.uiColor.cgColor
            radioInnerCircle.isHidden = false
        } else {
            radioButton.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
            radioInnerCircle.isHidden = true
        }
    }
}
