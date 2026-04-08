//
//  AddPlanTimeSelectionVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 29.12.2025.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit

public class AddPlanTimeSelectionVC: TRPBaseUIViewController, DynamicHeightPresentable {

    // MARK: - DynamicHeightPresentable
    public var preferredContentHeight: CGFloat {
        // Nav bar (56) + day filter margin (16) + day filter (48) + title margin (24) + title (24)
        // + collection margin (16) + collection (~196 for 4 rows) + button margin (16) + button (52) + bottom (16)
        return 56 + 16 + 48 + 24 + 24 + 16 + 196 + 16 + 52 + 16
    }

    // MARK: - Properties
    private var viewModel: AddPlanTimeSelectionViewModel!

    // Callback when time selection is completed
    public var onTimeSelected: ((Date, TimeSlot) -> Void)?

    // Callback when segment creation completes successfully, passes selected day for navigation
    public var onSegmentCreated: ((Date?) -> Void)?

    // Callback when segment update completes successfully (edit mode)
    public var onSegmentUpdated: (() -> Void)?

    // Callback when step update completes successfully (step edit mode)
    public var onStepUpdated: (() -> Void)?

    // MARK: - UI Components
    private var customNavigationBar: TRPTimelineCustomNavigationBar!

    private let dayFilterView: TRPTimelineDayFilterView = {
        let view = TRPTimelineDayFilterView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.selectATime)
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .white
        cv.delegate = self
        cv.dataSource = self
        cv.showsVerticalScrollIndicator = false
        cv.register(AddPlanTimeSlotCell.self, forCellWithReuseIdentifier: AddPlanTimeSlotCell.reuseIdentifier)
        return cv
    }()

    private lazy var continueButton: TRPButton = {
        let button = TRPButton(
            title: CommonLocalizationKeys.localized(CommonLocalizationKeys.continueButton),
            style: .primary
        )
        button.setEnabled(false)
        return button
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.noAvailableTimes)
        label.font = FontSet.montserratRegular.font(16)
        label.textColor = ColorSet.fgWeak.uiColor
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // MARK: - Initialization
    public init(tour: TRPTourProduct, planData: AddPlanData) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = AddPlanTimeSelectionViewModel(tour: tour, planData: planData)
        self.viewModel.delegate = self
    }

    /// Edit mode - for changing time of existing reserved activity
    public init(segment: TRPTimelineSegment, planData: AddPlanData) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = AddPlanTimeSelectionViewModel(segment: segment, planData: planData)
        self.viewModel.delegate = self
    }

    /// Step edit mode - for changing time of activity steps in recommendations
    public init(step: TRPTimelineStep, planData: AddPlanData) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = AddPlanTimeSelectionViewModel(step: step, planData: planData)
        self.viewModel.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDayFilter()
        setupActions()

        // Fetch time slots
        viewModel.fetchTimeSlots()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white

        // Setup navigation bar using base class method
        // Use different title for edit mode
        let navTitle = viewModel.isEditMode
            ? TimelineLocalizationKeys.localized(TimelineLocalizationKeys.changeTime)
            : AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.addPlan)
        customNavigationBar = setupCustomNavigationBar(title: navTitle)
        customNavigationBar.topPadding = 16
        customNavigationBar.delegate = self

        view.addSubview(dayFilterView)
        view.addSubview(titleLabel)
        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)
        view.addSubview(continueButton)
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            // Day Filter
            dayFilterView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor, constant: 16),
            dayFilterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dayFilterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dayFilterView.heightAnchor.constraint(equalToConstant: 74),

            // Title Label
            titleLabel.topAnchor.constraint(equalTo: dayFilterView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Collection View
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -16),

            // Continue Button
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Empty State Label
            emptyStateLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor, constant: 16),
            emptyStateLabel.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: -16),
        ])
    }

    private func setupDayFilter() {
        dayFilterView.delegate = self

        let days = viewModel.getAvailableDays()
        let selectedIndex = viewModel.getSelectedDayIndex()

        dayFilterView.configure(with: days, selectedDay: selectedIndex)
    }

    private func setupActions() {
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func continueTapped() {
        guard let selectedTimeSlot = viewModel.getSelectedTimeSlot(),
              let selectedDate = viewModel.getAvailableDays()[safe: viewModel.getSelectedDayIndex()] else {
            return
        }

        // Call existing callback (for compatibility)
        onTimeSelected?(selectedDate, selectedTimeSlot)

        // Create or update based on mode
        if viewModel.isStepEditMode {
            // Step edit mode - update activity step time
            viewModel.updateActivityStep()
        } else if viewModel.isEditMode {
            // Segment edit mode - update reserved activity segment time
            viewModel.updateReservedActivitySegment()
        } else {
            // Create mode - create new reserved activity segment
            viewModel.createReservedActivitySegment()
        }
    }

    // MARK: - Helpers
    private func updateContinueButton() {
        let canContinue = viewModel.canContinue()
        continueButton.setEnabled(canContinue)
    }
}

// MARK: - UICollectionViewDataSource
extension AddPlanTimeSelectionVC: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getTimeSlots().count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddPlanTimeSlotCell.reuseIdentifier, for: indexPath) as? AddPlanTimeSlotCell else {
            return UICollectionViewCell()
        }

        let timeSlots = viewModel.getTimeSlots()
        let timeSlot = timeSlots[indexPath.item]
        let isSelected = viewModel.getSelectedTimeSlot()?.time == timeSlot.time

        cell.configure(with: timeSlot, isSelected: isSelected)

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension AddPlanTimeSelectionVC: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let timeSlots = viewModel.getTimeSlots()
        let timeSlot = timeSlots[indexPath.item]

        viewModel.selectTimeSlot(timeSlot)
        collectionView.reloadData()
        updateContinueButton()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension AddPlanTimeSelectionVC: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 12
        let numberOfColumns: CGFloat = 4
        let totalSpacing = spacing * (numberOfColumns - 1)
        let width = (collectionView.bounds.width - totalSpacing) / numberOfColumns

        return CGSize(width: width, height: 40)
    }
}

// MARK: - AddPlanTimeSelectionViewModelDelegate
extension AddPlanTimeSelectionVC: AddPlanTimeSelectionViewModelDelegate {

    public func timeSlotsDidLoad() {
        let hasTimeSlots = !viewModel.getTimeSlots().isEmpty
        emptyStateLabel.isHidden = hasTimeSlots
        collectionView.reloadData()
    }

    public func timeSlotsDidFail(error: Error) {
        // Show error alert
        let errorTitle = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.error)
        let okTitle = TRPLanguagesController.shared.getLanguageValue(for: "ok")
        let alert = UIAlertController(title: errorTitle, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okTitle.isEmpty ? "OK" : okTitle, style: .default))
        present(alert, animated: true)
    }

    public func showLoading(_ show: Bool) {
        if show {
            loadingIndicator.startAnimating()
            collectionView.alpha = 0.5
            continueButton.setEnabled(false)
        } else {
            loadingIndicator.stopAnimating()
            collectionView.alpha = 1.0
            continueButton.setEnabled(viewModel.canContinue())
        }
    }

    public func segmentCreationDidSucceed() {
        // Get cleaned activity ID from the tour's productId
        let activityId = viewModel.tour.productId.cleanedAsActivityId()

        // Notify host app about activity addition
        TRPCoreKit.shared.delegate?.trpCoreKitDidAddActivity(activityId: activityId)

        // Dismiss and trigger timeline refresh with selected day for navigation
        dismiss(animated: true) { [weak self] in
            self?.onSegmentCreated?(self?.viewModel.getSelectedDate())
        }
    }

    public func segmentUpdateDidSucceed() {
        // Dismiss and trigger timeline refresh (edit mode)
        dismiss(animated: true) { [weak self] in
            self?.onSegmentUpdated?()
        }
    }

    public func stepUpdateDidSucceed() {
        // Dismiss and trigger timeline refresh (step edit mode)
        dismiss(animated: true) { [weak self] in
            self?.onStepUpdated?()
        }
    }
}

// MARK: - Array Safe Subscript
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - TRPTimelineDayFilterViewDelegate
extension AddPlanTimeSelectionVC: TRPTimelineDayFilterViewDelegate {

    public func dayFilterViewDidSelectDay(_ view: TRPTimelineDayFilterView, dayIndex: Int) {
        viewModel.selectDay(at: dayIndex)
        collectionView.reloadData()
        updateContinueButton()
    }
}

// MARK: - TRPTimelineCustomNavigationBarDelegate
extension AddPlanTimeSelectionVC: TRPTimelineCustomNavigationBarDelegate {

    func customNavigationBarDidTapBack(_ navigationBar: TRPTimelineCustomNavigationBar) {
        dismiss(animated: true)
    }
}
