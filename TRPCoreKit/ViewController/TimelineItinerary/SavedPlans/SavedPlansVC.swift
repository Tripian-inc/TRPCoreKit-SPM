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
    private var customNavigationBar: TRPTimelineCustomNavigationBar!

    /// Legacy "dismiss everything" path; internal flow prefers the silent variant below.
    public var onSegmentCreated: ((Date?) -> Void)?

    /// Fired after add + regeneration poll; Saved Plans stays open, host refreshes silently.
    public var onSegmentCreatedSilent: ((Date?) -> Void)?

    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
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

    /// "All done" placeholder shown once every saved activity is added and the list empties.
    private lazy var emptyStateView: SavedPlansEmptyStateView = {
        let view = SavedPlansEmptyStateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.onViewItineraryTapped = { [weak self] in
            self?.dismiss(animated: true)
        }
        return view
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
        navigationController?.setNavigationBarHidden(true, animated: false)
        viewModel.delegate = self
    }

    // MARK: - Setup Views
    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white

        customNavigationBar = setupCustomNavigationBar(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.savedPlans)
        )
        customNavigationBar.delegate = self

        view.addSubview(tableView)
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        updateEmptyState()
    }

    private func updateEmptyState() {
        let isEmpty = viewModel.getTotalItemCount() == 0
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
}

// MARK: - TRPTimelineCustomNavigationBarDelegate
extension SavedPlansVC: TRPTimelineCustomNavigationBarDelegate {

    func customNavigationBarDidTapBack(_ navigationBar: TRPTimelineCustomNavigationBar) {
        dismiss(animated: true)
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
            cell.configure(with: item, tourProduct: tourProduct)
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension SavedPlansVC: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // activityId may be raw or `C_{id}_{provider}` form — normalize to the bare product id.
        if let item = viewModel.getItem(at: indexPath),
           let activityId = item.activityId {
            TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: activityId.cleanedAsActivityId())
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
        let planData = viewModel.createAddPlanData(cityId: tour.cityId)
        let timeSelectionVC = AddPlanTimeSelectionVC(tour: tour, planData: planData)

        timeSelectionVC.onTimeSelected = { _, _ in }

        let activityName = tour.name
        let productId = tour.productId
        timeSelectionVC.onSegmentCreated = { [weak self] selectedDay in
            guard let self = self else { return }

            let dayLabel = selectedDay?.weekdayWithDayMonth() ?? ""
            let template = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.activityAddedToast)
            let message = String(format: template, activityName, dayLabel)
            TRPSuccessToast.show(over: self, message: message)

            self.viewModel.removeItem(matchingProductId: productId)

            self.onSegmentCreatedSilent?(selectedDay)
        }

        presentVCWithDynamicHeight(timeSelectionVC, prefersGrabberVisible: true, isDimmed: true)
    }
}

// MARK: - SavedPlansViewModelDelegate
extension SavedPlansVC: SavedPlansViewModelDelegate {

    public func savedPlansDidLoad() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
            self.updateEmptyState()
        }
    }
}
