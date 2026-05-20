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
        // Top chrome: nav bar + (day filter chrome) + title chrome. Step edit mode
        // hides the day filter (the step is locked to its own day) so the chrome
        // shrinks by the filter band + its top gap.
        let chrome: CGFloat
        if viewModel?.isStepEditMode == true {
            // nav bar + gap-to-title + title chrome
            chrome = 56 + 24 + 24
        } else {
            // nav bar + gap-to-day + day filter + gap-to-title + title chrome
            chrome = 56 + 16 + 48 + 24 + 24
        }
        // Bottom: 16pt gap above button + button (52) + home-indicator inset.
        // `safeAreaInsets` is 0 before the view is in a window, so fall back to 34pt
        // (typical home-indicator height) — close enough for the initial sheet sizing
        // and refined after `updateSheetHeight` runs post-layout.
        let safeAreaBottom = view.safeAreaInsets.bottom > 0 ? view.safeAreaInsets.bottom : 34
        let bottom: CGFloat = 16 + 52 + safeAreaBottom

        // viewModel may be force-unwrapped post-init, but guard defensively in case
        // this is queried before the model is ready.
        let allDaysUnavailable = viewModel?.allDaysUnavailable() == true
        let isFlexible = !allDaysUnavailable && viewModel?.isSelectedDayFlexible() == true

        let availableWidth = (view.bounds.width > 0)
            ? view.bounds.width
            : UIScreen.main.bounds.width
        let labelFont = FontSet.montserratMedium.font(14)
        // Card label width = view width − (16+16 outer h-margin) − (16 icon left + 20 icon + 8 gap + 16 label right)
        let cardLabelMaxWidth = max(0, availableWidth - 92)

        let middle: CGFloat
        if allDaysUnavailable {
            let bannerText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.activityNotAvailableForTrip)
            let bannerLabelHeight = Self.textHeight(for: bannerText, font: labelFont, maxWidth: cardLabelMaxWidth)
            let bannerHeight = 16 + max(20, bannerLabelHeight) + 16
            // 16 (banner top from title) + bannerHeight + 16 (banner bottom to button)
            middle = 16 + bannerHeight + 16
        } else if isFlexible {
            // Measure the live label texts at the available width so the sheet adapts
            // to translations and screen sizes — wrap-induced extra lines grow the
            // sheet just enough, no clipping.
            // Subtitle width = view width − (16+16 h-margin)
            let subtitleMaxWidth = max(0, availableWidth - 32)

            let cardLabelText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.flexibleTimeInfo)
            let subtitleText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.flexibleTimePinTopHint)

            let cardLabelHeight = Self.textHeight(for: cardLabelText, font: labelFont, maxWidth: cardLabelMaxWidth)
            let subtitleHeight = Self.textHeight(for: subtitleText, font: labelFont, maxWidth: subtitleMaxWidth)

            // Card: 16pt top padding + max(icon, label) + 16pt bottom padding.
            let cardHeight = 16 + max(20, cardLabelHeight) + 16

            // 16 (card top from title) + cardHeight + 8 (subtitle top from card)
            // + subtitleHeight + 32 (subtitle bottom to button)
            middle = 16 + cardHeight + 8 + subtitleHeight + 32
        } else {
            // Timed grid — height grows with the number of visible cells so the sheet
            // shrinks for short lists (1 row) and expands for long ones (≥3 rows).
            // The "Show more" affordance is rendered as the 8th cell, so it just
            // counts as one more slot in the grid for sizing purposes.
            // Cell: 40pt tall, 12pt line spacing, 4 columns.
            let displayedCount = viewModel?.getDisplayedTimeSlots().count ?? 0
            let extraForShowMore = (viewModel?.hasMoreTimeSlotsToShow() == true) ? 1 : 0
            let cellCount = displayedCount + extraForShowMore
            let rowCount = max(1, Int(ceil(Double(cellCount) / 4.0)))
            let cellHeight: CGFloat = 40
            let lineSpacing: CGFloat = 12
            let gridHeight = CGFloat(rowCount) * cellHeight + CGFloat(max(0, rowCount - 1)) * lineSpacing

            // Sold-out warning banner — present only in edit mode when the saved time
            // is missing from the schedule response. Sits directly above the continue
            // button with a 16pt gap on either side.
            let showSoldOut = viewModel?.shouldShowSoldOutWarning == true
            let soldOutContribution: CGFloat
            if showSoldOut {
                let soldOutText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.soldOutWarning)
                let soldOutLabelHeight = Self.textHeight(for: soldOutText, font: labelFont, maxWidth: cardLabelMaxWidth)
                let soldOutHeight = 16 + max(20, soldOutLabelHeight) + 16
                soldOutContribution = soldOutHeight + 16  // banner + gap to button
            } else {
                soldOutContribution = 0
            }

            // 16 (collection top) + grid + 16 (grid bottom gap) + [soldOut + 16]?
            middle = 16 + gridHeight + 16 + soldOutContribution
        }
        return chrome + middle + bottom
    }

    /// Measure the rendered height of `text` at the given font and width — used to
    /// size the dynamic-height sheet around translation-dependent label content.
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
    /// Container for flexible-time activities — info icon + descriptive text rendered
    /// in place of the time grid when the selected day has no specific slots.
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
        // Same icon family used by the listing screen's info button.
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
    /// Cream/orange warning card shown in place of the time grid when the activity
    /// has no availability on any day of the trip.
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
    /// Red-tinted warning shown above the continue button during change-time when the
    /// activity's previously-saved time is no longer in the schedule response (sold
    /// out or in the past). Paired with a disabled placeholder cell in the time grid
    /// at that slot. Visible only in edit mode.
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

    /// Bottom constraint pinning the collection view directly above the continue
    /// button (used when the sold-out banner is hidden).
    private var collectionViewBottomToContinue: NSLayoutConstraint!
    /// Bottom constraint pinning the collection view to the sold-out banner (used in
    /// edit mode when the activity's saved time is missing from the schedule).
    private var collectionViewBottomToSoldOutBanner: NSLayoutConstraint!

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
        view.addSubview(loadingIndicator)

        // Step edit mode (change-time for an itinerary activity step) is locked to
        // the step's own day — the user can't move an activity step to another
        // day from here. Hide the day filter and anchor the title directly under
        // the nav bar so the sheet doesn't reserve unused vertical chrome.
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
                dayFilterView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor, constant: 16),
                dayFilterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                dayFilterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                dayFilterView.heightAnchor.constraint(equalToConstant: 74),

                titleLabel.topAnchor.constraint(equalTo: dayFilterView.bottomAnchor, constant: 24),
                titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            ])
        }

        NSLayoutConstraint.activate([
            // Collection View — bottom anchor is wired to one of two constraints
            // (toggled in `updateBookingAvailabilityBanner`): directly to the continue
            // button when the banner is hidden, or to the banner top when visible.
            // The "Show more" link is rendered as the 8th cell inside the grid (not a
            // separate subview).
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

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

            // Flexible-time card — same top/leading/trailing as the collection view so it
            // takes the time grid's slot. Hidden by default; toggled in `timeSlotsDidLoad`.
            flexibleInfoCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            flexibleInfoCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            flexibleInfoCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // 20×20 info icon, 16pt from the card's top/left edges.
            flexibleInfoIcon.leadingAnchor.constraint(equalTo: flexibleInfoCard.leadingAnchor, constant: 16),
            flexibleInfoIcon.topAnchor.constraint(equalTo: flexibleInfoCard.topAnchor, constant: 16),
            flexibleInfoIcon.widthAnchor.constraint(equalToConstant: 20),
            flexibleInfoIcon.heightAnchor.constraint(equalToConstant: 20),

            // Message label — 16pt top/right/bottom margins; 8pt gap from icon.
            flexibleInfoLabel.topAnchor.constraint(equalTo: flexibleInfoCard.topAnchor, constant: 16),
            flexibleInfoLabel.bottomAnchor.constraint(equalTo: flexibleInfoCard.bottomAnchor, constant: -16),
            flexibleInfoLabel.leadingAnchor.constraint(equalTo: flexibleInfoIcon.trailingAnchor, constant: 8),
            flexibleInfoLabel.trailingAnchor.constraint(equalTo: flexibleInfoCard.trailingAnchor, constant: -16),

            // Subtitle hint — 8pt from the card; 16pt horizontal; pinned 16pt above the
            // continue button so it sits flush at the bottom when the flexible UI is shown
            // (the dynamic-height sheet then sizes the screen to fit just this content).
            flexibleSubtitleLabel.topAnchor.constraint(equalTo: flexibleInfoCard.bottomAnchor, constant: 8),
            flexibleSubtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            flexibleSubtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            flexibleSubtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: continueButton.topAnchor, constant: -32),

            // Unavailable banner — same horizontal alignment as the flexible card; takes
            // the time grid's slot when shown. Hidden by default.
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

            // Sold-out warning — sits directly above the continue button.
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

        // Two mutually-exclusive bottom constraints for the collection view, toggled
        // by `updateSoldOutBanner(_:)`:
        //   - sold-out hidden  → pinned to the continue button
        //   - sold-out visible → pinned to the sold-out banner top
        collectionViewBottomToContinue = collectionView.bottomAnchor.constraint(
            equalTo: continueButton.topAnchor, constant: -16
        )
        collectionViewBottomToSoldOutBanner = collectionView.bottomAnchor.constraint(
            equalTo: soldOutBanner.topAnchor, constant: -16
        )
        // Default: banner hidden, collection view extends to the continue button.
        collectionViewBottomToContinue.isActive = true
    }

    private func setupDayFilter() {
        dayFilterView.delegate = self

        let days = viewModel.getAvailableDays()
        let selectedIndex = viewModel.getSelectedDayIndex()

        dayFilterView.configure(with: days, selectedDay: selectedIndex, mode: .addPlan)
    }

    private func setupActions() {
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func continueTapped() {
        guard let selectedDate = viewModel.getAvailableDays()[safe: viewModel.getSelectedDayIndex()] else {
            return
        }
        // Flexible-time day: no slot is selected but Continue is still valid.
        let selectedTimeSlot = viewModel.getSelectedTimeSlot()
        guard selectedTimeSlot != nil || viewModel.isSelectedDayFlexible() else { return }

        // Call existing callback (for compatibility) only when an actual slot is picked.
        if let selectedTimeSlot = selectedTimeSlot {
            onTimeSelected?(selectedDate, selectedTimeSlot)
        }

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

    /// Expand the slot grid in response to a tap on the "Show more" cell. Reloads the
    /// collection view so the previously-clipped slots animate in, and refreshes the
    /// sheet detent because the grid now has more rows.
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

    /// Toggle the red sold-out warning and swap the collection view's bottom anchor
    /// to whichever element directly follows the grid (the banner when visible,
    /// otherwise the continue button).
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
        // Slot cells + one trailing "Show more" cell when the grid is collapsed and
        // the day has hidden slots. Renders as the 8th item in the 4-column grid.
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

    /// Disabled placeholder cells (the activity's saved time when sold out / past)
    /// are not selectable. The trailing "Show more" affordance is selectable so the
    /// tap handler can expand the grid.
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let timeSlots = viewModel.getDisplayedTimeSlots()
        guard indexPath.item < timeSlots.count else { return true }
        return !timeSlots[indexPath.item].isDisabled
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let displayedCount = viewModel.getDisplayedTimeSlots().count

        // Trailing "Show more" cell — expand the grid instead of selecting a slot.
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
        let hasTimeSlots = !allDaysUnavailable && !viewModel.getTimeSlots().isEmpty

        // No availability anywhere on the trip → swap every other state for the warning banner.
        unavailableBanner.isHidden = !allDaysUnavailable

        // Flexible day → info card replaces the grid; subtitle hint visible.
        flexibleInfoCard.isHidden = allDaysUnavailable || !isFlexible
        flexibleSubtitleLabel.isHidden = allDaysUnavailable || !isFlexible
        collectionView.isHidden = allDaysUnavailable || isFlexible
        emptyStateLabel.isHidden = allDaysUnavailable || isFlexible || hasTimeSlots

        // Sold-out warning shows only in edit mode when the saved time is missing
        // from the schedule for the activity's own day, and only when the timed grid
        // itself is visible (so flexible / fully-unavailable states skip it).
        let shouldShowSoldOutBanner = !allDaysUnavailable && !isFlexible && hasTimeSlots && viewModel.shouldShowSoldOutWarning
        updateSoldOutBanner(shouldShowSoldOutBanner)

        // The "Show more" cell is rendered inline by the data source as the 8th item
        // when the grid is collapsed and there are >8 slots — no separate visibility
        // toggle needed here.

        collectionView.reloadData()
        updateContinueButton()

        // Days the activity has no availability for render disabled in the day
        // filter, same as past dates. The VM also auto-shifts `selectedDate` if the
        // user landed on an unavailable day, so re-sync the visual selection here.
        dayFilterView.setUnavailableDayIndices(viewModel.unavailableDayIndices())
        dayFilterView.updateSelectedDay(viewModel.getSelectedDayIndex())

        // The bottom-sheet detent depends on which UI is showing — refresh so the
        // sheet shrinks for flexible (no grid) and grows back for timed days.
        updateSheetHeight()
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
        // DON'T dismiss here — the inline "Changing time" loader stays visible while
        // the host runs its timeline refresh. The host dismisses this sheet once the
        // refresh completes, which removes the loader along with the sheet. Avoids a
        // visual jump from inView loader → second bottom-sheet loader.
        onSegmentUpdated?()
    }

    public func stepUpdateDidSucceed() {
        // Same as `segmentUpdateDidSucceed` — host dismisses post-refresh.
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
