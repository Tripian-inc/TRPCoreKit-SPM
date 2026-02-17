//
//  AddPlanPOIFilterVC.swift
//  TRPCoreKit
//
//  Created by Cem Caygoz on 23.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

// MARK: - AddPlanPOIFilterVC
public class AddPlanPOIFilterVC: TRPBaseUIViewController, DynamicHeightPresentable {

    // MARK: - DynamicHeightPresentable
    public var preferredContentHeight: CGFloat {
        // Header (56) + separator (0.5) + top margin (24) + rows (N * 52) + button container (80)
        let rowCount = viewModel.getCategoryCount()
        return 56 + 0.5 + 24 + CGFloat(rowCount * 52) + 80
    }

    // MARK: - Properties
    private var viewModel: AddPlanPOIFilterViewModel
    public var onFilterApplied: ((POIFilterData) -> Void)?

    // MARK: - UI Components
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.filters)
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(TRPImageController().getImage(inFramework: "ic_close", inApp: nil), for: .normal)
        button.tintColor = ColorSet.primaryText.uiColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.neutral200.uiColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private let buttonContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var clearButton: TRPButton = {
        let button = TRPButton(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.clearSelection),
            style: .secondary
        )
        return button
    }()

    private lazy var confirmButton: TRPButton = {
        let button = TRPButton(
            title: CommonLocalizationKeys.localized(CommonLocalizationKeys.confirm),
            style: .primary
        )
        return button
    }()

    // MARK: - Initialization
    public init(categoryType: POIListingCategoryType, filterData: POIFilterData = POIFilterData()) {
        self.viewModel = AddPlanPOIFilterViewModel(categoryType: categoryType, filterData: filterData)
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
        view.addSubview(separatorView)
        view.addSubview(tableView)
        view.addSubview(buttonContainerView)
        buttonContainerView.addSubview(clearButton)
        buttonContainerView.addSubview(confirmButton)

        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(POIFilterCategoryCell.self, forCellReuseIdentifier: POIFilterCategoryCell.reuseIdentifier)

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

            // Separator
            separatorView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),

            // Table view
            tableView.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: buttonContainerView.topAnchor),

            // Button container view
            buttonContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            buttonContainerView.heightAnchor.constraint(equalToConstant: 80),

            // Clear button (left)
            clearButton.leadingAnchor.constraint(equalTo: buttonContainerView.leadingAnchor, constant: 16),
            clearButton.topAnchor.constraint(equalTo: buttonContainerView.topAnchor, constant: 16),

            // Confirm button (right)
            confirmButton.leadingAnchor.constraint(equalTo: clearButton.trailingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: buttonContainerView.trailingAnchor, constant: -16),
            confirmButton.topAnchor.constraint(equalTo: buttonContainerView.topAnchor, constant: 16),
            confirmButton.widthAnchor.constraint(equalTo: clearButton.widthAnchor)
        ])
    }

    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func clearButtonTapped() {
        viewModel.clearSelection()
        tableView.reloadData()
    }

    @objc private func confirmButtonTapped() {
        onFilterApplied?(viewModel.getFilterData())
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension AddPlanPOIFilterVC: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getCategoryCount()
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: POIFilterCategoryCell.reuseIdentifier, for: indexPath) as? POIFilterCategoryCell else {
            return UITableViewCell()
        }

        let categoryName = viewModel.getCategoryName(at: indexPath.row)
        let isSelected = viewModel.isCategorySelected(at: indexPath.row)
        cell.configure(title: categoryName, isSelected: isSelected)

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        viewModel.toggleCategory(at: indexPath.row)
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }
}
