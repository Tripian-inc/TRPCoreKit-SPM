//
//  SavedPlansVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 29.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

@objc(SPMSavedPlansVC)
public class SavedPlansVC: TRPBaseUIViewController {

    // MARK: - Properties
    private var viewModel: SavedPlansViewModel!

    // Callback when segment is created successfully
    public var onSegmentCreated: (() -> Void)?

    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(ActivityCardCell.self, forCellReuseIdentifier: ActivityCardCell.reuseIdentifier)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        return tableView
    }()

    // MARK: - Initialization
    public init(viewModel: SavedPlansViewModel) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        viewModel.delegate = self
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        title = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.savedPlans)
        navigationController?.navigationBar.prefersLargeTitles = false

        // Add back button
        let backButton = UIBarButtonItem(
            image: TRPImageController().getImage(inFramework: "ic_back", inApp: nil),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = ColorSet.primaryText.uiColor
        navigationItem.leftBarButtonItem = backButton

        // Navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [
            .foregroundColor: ColorSet.primaryText.uiColor,
            .font: FontSet.montserratSemiBold.font(18)
        ]
        appearance.shadowColor = ColorSet.lineWeak.uiColor

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }

    // MARK: - Setup Views
    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource
extension SavedPlansVC: UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(in: section)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ActivityCardCell.reuseIdentifier, for: indexPath) as? ActivityCardCell else {
            return UITableViewCell()
        }

        cell.delegate = self

        if let item = viewModel.getItem(at: indexPath),
           let tourProduct = viewModel.convertToTourProduct(from: item) {
            // Use the new configure method that shows cancellation and proper price formatting
            cell.configure(with: item, tourProduct: tourProduct)
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension SavedPlansVC: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Open activity detail
        if let item = viewModel.getItem(at: indexPath),
           let activityId = item.activityId {
            TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: activityId)
        }
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionData = viewModel.getSection(at: section) else { return nil }

        let headerView = UIView()
        headerView.backgroundColor = .white

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = sectionData.cityName
        label.font = FontSet.montserratSemiBold.font(20)
        label.textColor = ColorSet.primaryText.uiColor

        headerView.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])

        return headerView
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
}

// MARK: - ActivityCardCellDelegate
extension SavedPlansVC: ActivityCardCellDelegate {

    func activityCardCellDidTapAdd(_ cell: ActivityCardCell, tour: TRPTourProduct) {
        // Create time selection screen
        let planData = viewModel.createAddPlanData()
        let timeSelectionVC = AddPlanTimeSelectionVC(tour: tour, planData: planData)

        timeSelectionVC.onTimeSelected = { [weak self] selectedDate, selectedTimeSlot in
            print("Selected date: \(selectedDate), time: \(selectedTimeSlot.time)")
        }

        // Set segment creation callback
        timeSelectionVC.onSegmentCreated = { [weak self] in
            // First dismiss time selection, then dismiss saved plans
            self?.dismiss(animated: true) { [weak self] in
                // Trigger parent callback to refresh timeline
                self?.onSegmentCreated?()
            }
        }

        // Present as bottom sheet
        presentVCWithModal(timeSelectionVC, onlyLarge: true, prefersGrabberVisible: false)
    }
}

// MARK: - SavedPlansViewModelDelegate
extension SavedPlansVC: SavedPlansViewModelDelegate {

    public func savedPlansDidLoad() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
}
