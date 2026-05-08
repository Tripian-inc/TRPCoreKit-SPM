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

    // Callback when segment is created successfully, passes selected day for navigation.
    // Legacy "dismiss everything" path; left in place for any external caller still wired
    // to it. Internal flow now prefers the silent variant below.
    public var onSegmentCreated: ((Date?) -> Void)?

    /// Callback fired AFTER the activity has been added and the timeline regeneration
    /// poll has completed. Saved Plans stays open (no dismiss); the host VC is expected
    /// to refresh its timeline silently (e.g. apply pending day navigation). Mirrors
    /// `AddPlanActivityListingVC.onSegmentCreatedSilent` so both add-to-itinerary entry
    /// points behave the same — keep the listing visible, show a success toast on it.
    public var onSegmentCreatedSilent: ((Date?) -> Void)?

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
        navigationController?.setNavigationBarHidden(true, animated: false)
        viewModel.delegate = self
    }

    // MARK: - Setup Views
    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white

        // Setup navigation bar using base class method
        customNavigationBar = setupCustomNavigationBar(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.savedPlans)
        )
        customNavigationBar.delegate = self

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
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
        // Create time selection screen with the activity's own city
        let planData = viewModel.createAddPlanData(cityId: tour.cityId)
        let timeSelectionVC = AddPlanTimeSelectionVC(tour: tour, planData: planData)

        timeSelectionVC.onTimeSelected = { _, _ in }

        // Capture the activity name + product id; day label comes from the Date extension.
        // Mirrors the ActivityListing flow: keep Saved Plans visible, show a success toast
        // on it, and let the host refresh the timeline silently. The "Adding…" Lottie loader
        // is shown inside the time-selection sheet for the entire create + GetTimeline poll
        // window, so by the time this callback fires the regeneration is already done.
        let activityName = tour.name
        let productId = tour.productId
        timeSelectionVC.onSegmentCreated = { [weak self] selectedDay in
            guard let self = self else { return }

            let dayLabel = selectedDay?.weekdayWithDayMonth() ?? ""
            let template = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.activityAddedToast)
            let message = String(format: template, activityName, dayLabel)
            TRPSuccessToast.show(over: self, message: message)

            // Drop the just-added activity from the saved-plans list so the user sees it
            // disappear immediately. The VM fires `savedPlansDidLoad` after mutating, which
            // reloads the table for us.
            self.viewModel.removeItem(matchingProductId: productId)

            // Stay on Saved Plans — host VC refreshes the timeline silently.
            self.onSegmentCreatedSilent?(selectedDay)
        }

        // Present as dynamic height bottom sheet
        presentVCWithDynamicHeight(timeSelectionVC, prefersGrabberVisible: true, isDimmed: true)
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
