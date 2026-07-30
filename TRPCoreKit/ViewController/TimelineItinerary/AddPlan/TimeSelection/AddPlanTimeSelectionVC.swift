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
        // Step edit mode hides the day filter (step locked to its own day), so its chrome is shorter.
        let chrome: CGFloat
        if viewModel?.isStepEditMode == true {
            chrome = 56 + 24 + 24
        } else {
            // ...+ "Add to day" label top (25) + label (16) + gap (16) above the day filter.
            chrome = 56 + 25 + 16 + 16 + 48 + 24 + 24
        }
        // `safeAreaInsets` is 0 before the view is in a window; fall back to 34pt and refine post-layout.
        let safeAreaBottom = view.safeAreaInsets.bottom > 0 ? view.safeAreaInsets.bottom : 34
        // SavedPlans / change-time stacks a Remove button (48) + 12 spacing under the primary button.
        let bottom: CGFloat = 16 + 52 + (showsRemoveButton ? 60 : 0) + safeAreaBottom

        let allDaysUnavailable = viewModel?.allDaysUnavailable() == true
        let isFlexible = !allDaysUnavailable && viewModel?.isSelectedDayFlexible() == true

        let availableWidth = (view.bounds.width > 0)
            ? view.bounds.width
            : UIScreen.main.bounds.width
        let labelFont = FontSet.montserratMedium.font(14)
        let cardLabelMaxWidth = max(0, availableWidth - 92)

        let middle: CGFloat
        if allDaysUnavailable {
            let bannerText = viewModel?.unavailableBannerText() ?? ""
            let bannerLabelHeight = Self.textHeight(for: bannerText, font: labelFont, maxWidth: cardLabelMaxWidth)
            let bannerHeight = 16 + max(20, bannerLabelHeight) + 16
            middle = 16 + bannerHeight + 16
        } else if isFlexible {
            // Measure live label heights so the sheet adapts to translation-induced wrapping without clipping.
            let subtitleMaxWidth = max(0, availableWidth - 32)

            let cardLabelText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.flexibleTimeInfo)
            let subtitleText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.flexibleTimePinTopHint)

            let cardLabelHeight = Self.textHeight(for: cardLabelText, font: labelFont, maxWidth: cardLabelMaxWidth)
            let subtitleHeight = Self.textHeight(for: subtitleText, font: labelFont, maxWidth: subtitleMaxWidth)

            let cardHeight = 16 + max(20, cardLabelHeight) + 16

            middle = 16 + cardHeight + 8 + subtitleHeight + 32
        } else {
            // Timed grid grows with visible cell count; the "Show more" affordance counts as one extra slot.
            let displayedCount = viewModel?.getDisplayedTimeSlots().count ?? 0
            let extraForShowMore = (viewModel?.hasMoreTimeSlotsToShow() == true) ? 1 : 0
            let cellCount = displayedCount + extraForShowMore
            let rowCount = max(1, Int(ceil(Double(cellCount) / 4.0)))
            let cellHeight: CGFloat = 40
            let lineSpacing: CGFloat = 12
            let gridHeight = CGFloat(rowCount) * cellHeight + CGFloat(max(0, rowCount - 1)) * lineSpacing

            // Sold-out banner present only in edit mode when the saved time is missing from the schedule.
            let showSoldOut = viewModel?.shouldShowSoldOutWarning == true
            let soldOutContribution: CGFloat
            if showSoldOut {
                let soldOutText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.soldOutWarning)
                let soldOutLabelHeight = Self.textHeight(for: soldOutText, font: labelFont, maxWidth: cardLabelMaxWidth)
                let soldOutHeight = 16 + max(20, soldOutLabelHeight) + 16
                soldOutContribution = soldOutHeight + 16
            } else {
                soldOutContribution = 0
            }

            middle = 16 + gridHeight + 16 + soldOutContribution
        }
        return chrome + middle + bottom
    }

    /// Measure the rendered height of `text` at the given font and width.
    private static func textHeight(for text: String, font: UIFont, maxWidth: CGFloat) -> CGFloat {
        guard maxWidth > 0 else { return 0 }
        let constrainedSize = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let bounding = (text as NSString).boundingRect(
            with: constrainedSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(bounding.height)
    }

    // MARK: - Properties
    private var viewModel: AddPlanTimeSelectionViewModel!

    public var onTimeSelected: ((Date, TimeSlot) -> Void)?

    /// Passes the selected day for navigation.
    public var onSegmentCreated: ((Date?) -> Void)?

    public var onSegmentUpdated: (() -> Void)?

    public var onStepUpdated: (() -> Void)?

    /// Set by SavedPlans to opt the sheet into the "Select + Remove" layout: the primary
    /// button reads "Select" and a Remove button appears below it. Invoked after the
    /// favourite has been removed so SavedPlans can drop it from its list.
    public var onRemoveFavourite: (() -> Void)?

    /// Set by the change-time presenter (segment/step edit) to drive the host's
    /// "remove from plan" flow when the Remove button is tapped.
    public var onRemoveFromPlan: (() -> Void)?

    private var isSavedPlansContext: Bool { onRemoveFavourite != nil }

    /// Remove button shows for SavedPlans (remove favourite) and change-time edit (remove from plan).
    private var showsRemoveButton: Bool { isSavedPlansContext || viewModel.isEditMode }

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
        label.font = FontSet.montserratLight.font(12)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    private let addToDayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratLight.font(12)
        label.textColor = ColorSet.fg.uiColor
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
        cv.register(AddPlanShowMoreSlotCell.self, forCellWithReuseIdentifier: AddPlanShowMoreSlotCell.reuseIdentifier)
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

    private lazy var removeButton: TRPButton = {
        let button = TRPButton(
            title: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.remove),
            style: .outlined
        )
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

    // MARK: - Flexible-time UI
    /// Shown in place of the time grid when the selected day has no specific slots.
    private let flexibleInfoCard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.infoBg.uiColor
        view.layer.cornerRadius = 8
        view.isHidden = true
        return view
    }()

    private let flexibleInfoIcon: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "info.circle")
        iv.tintColor = ColorSet.infoIcon.uiColor
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let flexibleInfoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.flexibleTimeInfo)
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fg.uiColor
        label.numberOfLines = 0
        return label
    }()

    private let flexibleSubtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.flexibleTimePinTopHint)
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fgWeak.uiColor
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // MARK: - All-days-unavailable banner
    /// Shown in place of the time grid when the activity has no availability on any trip day.
    private let unavailableBanner: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.warningBg.uiColor
        view.layer.cornerRadius = 8
        view.isHidden = true
        return view
    }()

    private let unavailableBannerIcon: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "exclamationmark.triangle")
        iv.tintColor = ColorSet.warningIcon.uiColor
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let unavailableBannerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.activityNotAvailableForTrip)
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fg.uiColor
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Sold-out warning banner
    /// Edit-mode warning when the activity's saved time is no longer in the schedule (sold out / past).
    private let soldOutBanner: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.errorBg.uiColor
        view.layer.cornerRadius = 8
        view.isHidden = true
        return view
    }()

    private let soldOutBannerIcon: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = TRPImageController().getImage(inFramework: "ic_error_popup", inApp: nil)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let soldOutBannerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.soldOutWarning)
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fg.uiColor
        label.numberOfLines = 0
        return label
    }()

    /// Pins the collection view above the continue button (sold-out banner hidden).
    private var collectionViewBottomToContinue: NSLayoutConstraint!
    /// Pins the collection view above the sold-out banner (banner visible).
    private var collectionViewBottomToSoldOutBanner: NSLayoutConstraint!

    // MARK: - Initialization
    /// - Parameter alreadyAddedDays: "yyyy-MM-dd" days already holding this activity; rendered unselectable.
    public init(tour: TRPTourProduct, planData: AddPlanData, alreadyAddedDays: Set<String> = []) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = AddPlanTimeSelectionViewModel(tour: tour,
                                                       planData: planData,
                                                       alreadyAddedDays: alreadyAddedDays)
        self.viewModel.delegate = self
    }

    /// Edit mode — change time of an existing reserved activity.
    public init(segment: TRPTimelineSegment, planData: AddPlanData) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = AddPlanTimeSelectionViewModel(segment: segment, planData: planData)
        self.viewModel.delegate = self
    }

    /// Step edit mode — change time of an activity step in recommendations.
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

        viewModel.fetchTimeSlots()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white

        let navTitle = viewModel.isEditMode
            ? TimelineLocalizationKeys.localized(TimelineLocalizationKeys.changeTime)
            : AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.addPlan)
        customNavigationBar = setupCustomNavigationBar(title: navTitle)
        customNavigationBar.topPadding = 16
        customNavigationBar.delegate = self

        view.addSubview(dayFilterView)
        if !viewModel.isStepEditMode {
            addToDayLabel.text = AddPlanLocalizationKeys.localized(
                viewModel.isEditMode ? AddPlanLocalizationKeys.moveDay : AddPlanLocalizationKeys.addToDay
            )
            view.addSubview(addToDayLabel)
        }
        view.addSubview(titleLabel)
        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)
        view.addSubview(flexibleInfoCard)
        flexibleInfoCard.addSubview(flexibleInfoIcon)
        flexibleInfoCard.addSubview(flexibleInfoLabel)
        view.addSubview(flexibleSubtitleLabel)
        view.addSubview(unavailableBanner)
        unavailableBanner.addSubview(unavailableBannerIcon)
        unavailableBanner.addSubview(unavailableBannerLabel)
        view.addSubview(soldOutBanner)
        soldOutBanner.addSubview(soldOutBannerIcon)
        soldOutBanner.addSubview(soldOutBannerLabel)
        view.addSubview(continueButton)
        if showsRemoveButton {
            view.addSubview(removeButton)
        }
        view.addSubview(loadingIndicator)

        // Step edit mode is locked to the step's own day: hide the day filter and pin the title under the nav bar.
        let hideDayFilter = viewModel.isStepEditMode
        dayFilterView.isHidden = hideDayFilter

        if hideDayFilter {
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor, constant: 24),
                titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            ])
        } else {
            NSLayoutConstraint.activate([
                addToDayLabel.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor, constant: 25),
                addToDayLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                addToDayLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

                dayFilterView.topAnchor.constraint(equalTo: addToDayLabel.bottomAnchor, constant: 16),
                dayFilterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                dayFilterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                dayFilterView.heightAnchor.constraint(equalToConstant: 74),

                titleLabel.topAnchor.constraint(equalTo: dayFilterView.bottomAnchor, constant: 24),
                titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            ])
        }

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor, constant: 16),
            emptyStateLabel.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: -16),

            flexibleInfoCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            flexibleInfoCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            flexibleInfoCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            flexibleInfoIcon.leadingAnchor.constraint(equalTo: flexibleInfoCard.leadingAnchor, constant: 16),
            flexibleInfoIcon.topAnchor.constraint(equalTo: flexibleInfoCard.topAnchor, constant: 16),
            flexibleInfoIcon.widthAnchor.constraint(equalToConstant: 20),
            flexibleInfoIcon.heightAnchor.constraint(equalToConstant: 20),

            flexibleInfoLabel.topAnchor.constraint(equalTo: flexibleInfoCard.topAnchor, constant: 16),
            flexibleInfoLabel.bottomAnchor.constraint(equalTo: flexibleInfoCard.bottomAnchor, constant: -16),
            flexibleInfoLabel.leadingAnchor.constraint(equalTo: flexibleInfoIcon.trailingAnchor, constant: 8),
            flexibleInfoLabel.trailingAnchor.constraint(equalTo: flexibleInfoCard.trailingAnchor, constant: -16),

            flexibleSubtitleLabel.topAnchor.constraint(equalTo: flexibleInfoCard.bottomAnchor, constant: 8),
            flexibleSubtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            flexibleSubtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            flexibleSubtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: continueButton.topAnchor, constant: -32),

            unavailableBanner.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            unavailableBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            unavailableBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            unavailableBannerIcon.leadingAnchor.constraint(equalTo: unavailableBanner.leadingAnchor, constant: 16),
            unavailableBannerIcon.topAnchor.constraint(equalTo: unavailableBanner.topAnchor, constant: 16),
            unavailableBannerIcon.widthAnchor.constraint(equalToConstant: 20),
            unavailableBannerIcon.heightAnchor.constraint(equalToConstant: 20),

            unavailableBannerLabel.topAnchor.constraint(equalTo: unavailableBanner.topAnchor, constant: 16),
            unavailableBannerLabel.bottomAnchor.constraint(equalTo: unavailableBanner.bottomAnchor, constant: -16),
            unavailableBannerLabel.leadingAnchor.constraint(equalTo: unavailableBannerIcon.trailingAnchor, constant: 8),
            unavailableBannerLabel.trailingAnchor.constraint(equalTo: unavailableBanner.trailingAnchor, constant: -16),

            soldOutBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            soldOutBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            soldOutBanner.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -16),

            soldOutBannerIcon.leadingAnchor.constraint(equalTo: soldOutBanner.leadingAnchor, constant: 16),
            soldOutBannerIcon.topAnchor.constraint(equalTo: soldOutBanner.topAnchor, constant: 16),
            soldOutBannerIcon.widthAnchor.constraint(equalToConstant: 20),
            soldOutBannerIcon.heightAnchor.constraint(equalToConstant: 20),

            soldOutBannerLabel.topAnchor.constraint(equalTo: soldOutBanner.topAnchor, constant: 16),
            soldOutBannerLabel.bottomAnchor.constraint(equalTo: soldOutBanner.bottomAnchor, constant: -16),
            soldOutBannerLabel.leadingAnchor.constraint(equalTo: soldOutBannerIcon.trailingAnchor, constant: 8),
            soldOutBannerLabel.trailingAnchor.constraint(equalTo: soldOutBanner.trailingAnchor, constant: -16),
        ])

        // Two mutually-exclusive bottom constraints toggled by `updateSoldOutBanner(_:)`.
        collectionViewBottomToContinue = collectionView.bottomAnchor.constraint(
            equalTo: continueButton.topAnchor, constant: -16
        )
        collectionViewBottomToSoldOutBanner = collectionView.bottomAnchor.constraint(
            equalTo: soldOutBanner.topAnchor, constant: -16
        )
        collectionViewBottomToContinue.isActive = true

        // SavedPlans context: primary button becomes "Select".
        if isSavedPlansContext {
            continueButton.updateTitle(CommonLocalizationKeys.localized(CommonLocalizationKeys.select))
        }
        // SavedPlans (remove favourite) or change-time (remove from plan): stack a Remove button below.
        if showsRemoveButton {
            NSLayoutConstraint.activate([
                removeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                removeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                removeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                continueButton.bottomAnchor.constraint(equalTo: removeButton.topAnchor, constant: -12),
            ])
        } else {
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true
        }
    }

    private func setupDayFilter() {
        dayFilterView.delegate = self

        let days = viewModel.getAvailableDays()
        let selectedIndex = viewModel.getSelectedDayIndex()

        dayFilterView.configure(with: days, selectedDay: selectedIndex, mode: .addPlan)
    }

    private func setupActions() {
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        if showsRemoveButton {
            removeButton.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
        }
    }

    // MARK: - Actions
    @objc private func continueTapped() {
        guard let selectedDate = viewModel.getAvailableDays()[safe: viewModel.getSelectedDayIndex()] else {
            return
        }
        // Flexible-time day: no slot is selected but Continue is still valid.
        let selectedTimeSlot = viewModel.getSelectedTimeSlot()
        guard selectedTimeSlot != nil || viewModel.isSelectedDayFlexible() else { return }

        if let selectedTimeSlot = selectedTimeSlot {
            onTimeSelected?(selectedDate, selectedTimeSlot)
        }

        if viewModel.isStepEditMode {
            viewModel.updateActivityStep()
        } else if viewModel.isEditMode {
            viewModel.updateReservedActivitySegment()
        } else {
            viewModel.createReservedActivitySegment()
        }
    }

    @objc private func removeButtonTapped() {
        if isSavedPlansContext {
            showConfirmAlert(
                title: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.removeFavouriteTitle),
                message: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.removeFavouriteMessage),
                confirmTitle: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.remove),
                cancelTitle: CommonLocalizationKeys.localized(CommonLocalizationKeys.cancel),
                btnConfirmAction: { [weak self] in
                    guard let self = self else { return }
                    let baseId = self.viewModel.excludeFavouriteFromTimeline()
                    TRPCoreKit.shared.delegate?.trpCoreKitDidRemoveFavorite(activityId: baseId)
                    self.dismiss(animated: true) {
                        self.onRemoveFavourite?()
                    }
                }
            )
            return
        }

        // Change-time (edit) mode: confirm over the still-open sheet, then dismiss and run the
        // host's remove-from-plan flow (removeSegment / removeStep, no second confirm).
        let isStep = viewModel.isStepEditMode
        let titleKey = isStep ? TimelineLocalizationKeys.removeStepTitle : TimelineLocalizationKeys.removeActivityTitle
        let messageKey = isStep ? TimelineLocalizationKeys.removeStepMessage : TimelineLocalizationKeys.removeActivityMessage
        showConfirmAlert(
            title: TimelineLocalizationKeys.localized(titleKey),
            message: TimelineLocalizationKeys.localized(messageKey),
            confirmTitle: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.remove),
            cancelTitle: CommonLocalizationKeys.localized(CommonLocalizationKeys.cancel),
            btnConfirmAction: { [weak self] in
                self?.dismiss(animated: true) {
                    self?.onRemoveFromPlan?()
                }
            }
        )
    }

    /// Expand the slot grid on a "Show more" tap and refresh the sheet detent for the new rows.
    private func handleShowMoreTapped() {
        viewModel.expandTimeSlots()
        collectionView.reloadData()
        updateSheetHeight()
    }

    // MARK: - Helpers
    private func updateContinueButton() {
        let canContinue = viewModel.canContinue()
        continueButton.setEnabled(canContinue)
    }

    /// Toggle the sold-out warning and swap the collection view's bottom anchor accordingly.
    private func updateSoldOutBanner(_ showSoldOut: Bool) {
        soldOutBanner.isHidden = !showSoldOut

        collectionViewBottomToContinue.isActive = false
        collectionViewBottomToSoldOutBanner.isActive = false

        if showSoldOut {
            collectionViewBottomToSoldOutBanner.isActive = true
        } else {
            collectionViewBottomToContinue.isActive = true
        }
    }
}

// MARK: - UICollectionViewDataSource
extension AddPlanTimeSelectionVC: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Slot cells plus a trailing "Show more" cell when the grid is collapsed with hidden slots.
        let displayedCount = viewModel.getDisplayedTimeSlots().count
        let extraForShowMore = viewModel.hasMoreTimeSlotsToShow() ? 1 : 0
        return displayedCount + extraForShowMore
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let displayedCount = viewModel.getDisplayedTimeSlots().count
        let isShowMoreItem = viewModel.hasMoreTimeSlotsToShow() && indexPath.item == displayedCount

        if isShowMoreItem {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddPlanShowMoreSlotCell.reuseIdentifier, for: indexPath) as? AddPlanShowMoreSlotCell else {
                return UICollectionViewCell()
            }
            let title = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.showMoreTimeSlots)
            cell.configure(title: title)
            return cell
        }

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddPlanTimeSlotCell.reuseIdentifier, for: indexPath) as? AddPlanTimeSlotCell else {
            return UICollectionViewCell()
        }

        let timeSlots = viewModel.getDisplayedTimeSlots()
        let timeSlot = timeSlots[indexPath.item]
        let isSelected = viewModel.getSelectedTimeSlot()?.time == timeSlot.time

        cell.configure(with: timeSlot, isSelected: isSelected)

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension AddPlanTimeSelectionVC: UICollectionViewDelegate {

    /// Disabled placeholder cells (sold-out/past saved time) aren't selectable; "Show more" is.
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let timeSlots = viewModel.getDisplayedTimeSlots()
        guard indexPath.item < timeSlots.count else { return true }
        return !timeSlots[indexPath.item].isDisabled
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let displayedCount = viewModel.getDisplayedTimeSlots().count

        // Trailing "Show more" cell expands the grid instead of selecting a slot.
        if viewModel.hasMoreTimeSlotsToShow() && indexPath.item == displayedCount {
            handleShowMoreTapped()
            return
        }

        let timeSlots = viewModel.getDisplayedTimeSlots()
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
        let allDaysUnavailable = viewModel.allDaysUnavailable()
        let isFlexible = !allDaysUnavailable && viewModel.isSelectedDayFlexible()
        // Use *displayed* slots (incl. the edit-mode disabled placeholder) so the saved time shows as disabled rather than empty.
        let hasTimeSlots = !allDaysUnavailable && !viewModel.getDisplayedTimeSlots().isEmpty

        unavailableBanner.isHidden = !allDaysUnavailable
        unavailableBannerLabel.text = viewModel.unavailableBannerText()

        flexibleInfoCard.isHidden = allDaysUnavailable || !isFlexible
        flexibleSubtitleLabel.isHidden = allDaysUnavailable || !isFlexible
        collectionView.isHidden = allDaysUnavailable || isFlexible
        emptyStateLabel.isHidden = allDaysUnavailable || isFlexible || hasTimeSlots

        // Sold-out warning only in edit mode, on the activity's own day, when the timed grid is visible.
        let shouldShowSoldOutBanner = !allDaysUnavailable && !isFlexible && hasTimeSlots && viewModel.shouldShowSoldOutWarning
        updateSoldOutBanner(shouldShowSoldOutBanner)

        collectionView.reloadData()
        updateContinueButton()

        // Unavailable days render disabled in the filter; re-sync the visual selection here.
        dayFilterView.setUnavailableDayIndices(viewModel.unavailableDayIndices())
        dayFilterView.updateSelectedDay(viewModel.getSelectedDayIndex())

        updateSheetHeight()
    }

    public func timeSlotsDidFail(error: Error) {
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
        let activityId = viewModel.tour.productId.cleanedAsActivityId()

        TRPCoreKit.shared.delegate?.trpCoreKitDidAddActivity(activityId: activityId)

        dismiss(animated: true) { [weak self] in
            self?.onSegmentCreated?(self?.viewModel.getSelectedDate())
        }
    }

    public func segmentUpdateDidSucceed() {
        // Don't dismiss — the inline "Changing time" loader must stay until the host dismisses post-refresh.
        onSegmentUpdated?()
    }

    public func stepUpdateDidSucceed() {
        // Host dismisses post-refresh, same as `segmentUpdateDidSucceed`.
        onStepUpdated?()
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
        let days = viewModel.getAvailableDays()
        guard dayIndex < days.count, !days[dayIndex].isPastDay() else { return }
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
