//
//  AddPlanContainerVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

public protocol AddPlanContainerVCDelegate: AnyObject {
    func addPlanContainerDidComplete(_ viewController: AddPlanContainerVC, data: AddPlanData)
    func addPlanContainerDidCancel(_ viewController: AddPlanContainerVC)
    func addPlanContainerShouldShowActivityListing(_ viewController: AddPlanContainerVC, data: AddPlanData)
    func addPlanContainerShouldShowPOIListing(_ viewController: AddPlanContainerVC, data: AddPlanData, categoryType: POIListingCategoryType)
    func addPlanContainerSegmentCreated(_ viewController: AddPlanContainerVC)
}

/// Protocol for child view controllers to provide their preferred content height
public protocol AddPlanChildViewController: UIViewController {
    /// The preferred height for this step's content (excluding header and footer)
    var preferredContentHeight: CGFloat { get }
}

@objc(SPMAddPlanContainerVC)
public class AddPlanContainerVC: TRPBaseUIViewController, DynamicHeightPresentable {

    // MARK: - Constants
    private let headerHeight: CGFloat = 44
    private let headerTopPadding: CGFloat = 16
    private let footerHeight: CGFloat = 64 // 16pt spacing + ~48pt button
    private let safeAreaBottomPadding: CGFloat = 0 // Approximate safe area for devices with home indicator
    
    // MARK: - Properties
    public var viewModel: AddPlanContainerViewModel!
    public weak var delegate: AddPlanContainerVCDelegate?
    private var viewControllers: [UIViewController] = []
    private var currentChildVC: UIViewController?
    
    // MARK: - UI Components - Sticky Header
    private let headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TRPImageController().getImage(inFramework: "ic_back", inApp: nil), for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TRPImageController().getImage(inFramework: "ic_close", inApp: nil), for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        return button
    }()
    
    // MARK: - Content Container with Scroll
    private let contentScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        return scrollView
    }()

    private let contentContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    private var contentHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Sticky Footer
    private let footerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        return stackView
    }()
    
    private lazy var clearSelectionButton: TRPButton = {
        let button = TRPButton(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.clearSelection),
            style: .secondary
        )
        return button
    }()

    private lazy var continueButton: TRPButton = {
        let button = TRPButton(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.continueButton),
            style: .primary
        )
        button.setEnabled(false) // Start disabled
        return button
    }()
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()

        // Prevent dismissal by tapping outside (X button is available for closing)
        isModalInPresentation = true

        viewModel.delegate = self
        viewModel.start()
    }
    
    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white

        setupHeader()
        setupFooter()  // Add footer to hierarchy first
        setupContentContainer()  // Then set up content container (which references footer)
        setupActions()
    }

    // MARK: - Setup Methods
    private func setupHeader() {
        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            // Header View
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            // Back Button
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 24),
            backButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Title
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -4),
            
            // Close Button
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 18),
            closeButton.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    private func setupContentContainer() {
        view.addSubview(contentScrollView)
        contentScrollView.addSubview(contentContainerView)

        // Content height constraint - will be updated based on child VC
        contentHeightConstraint = contentContainerView.heightAnchor.constraint(equalToConstant: 400)

        NSLayoutConstraint.activate([
            // ScrollView fills the space between header and footer
            contentScrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: footerView.topAnchor),

            // Content container inside scroll view
            contentContainerView.topAnchor.constraint(equalTo: contentScrollView.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: contentScrollView.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: contentScrollView.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: contentScrollView.bottomAnchor),
            contentContainerView.widthAnchor.constraint(equalTo: contentScrollView.widthAnchor),
            contentHeightConstraint!
        ])
    }

    private func setupFooter() {
        view.addSubview(footerView)
        footerView.addSubview(buttonStackView)

        // Add buttons to stack view
        buttonStackView.addArrangedSubview(clearSelectionButton)
        buttonStackView.addArrangedSubview(continueButton)

        NSLayoutConstraint.activate([
            // Footer View
            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            footerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Stack View - 16pt from top of footer (which is bottom of content)
            buttonStackView.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 16),
            buttonStackView.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: footerView.bottomAnchor)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        clearSelectionButton.addTarget(self, action: #selector(clearSelectionTapped), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - DynamicHeightPresentable
    public var preferredContentHeight: CGFloat {
        // Get content height from current child VC
        let contentHeight: CGFloat
        if let childVC = currentChildVC as? AddPlanChildViewController {
            contentHeight = childVC.preferredContentHeight
        } else {
            // Default content height if child doesn't conform
            contentHeight = 400
        }

        // Total height = header + content + footer + safe area
        let totalHeight = headerTopPadding + headerHeight + contentHeight + footerHeight + safeAreaBottomPadding
        return totalHeight
    }

    // MARK: - Public Methods
    public func addViewController(_ viewController: UIViewController) {
        viewControllers.append(viewController)
    }

    public func setContinueButtonEnabled(_ enabled: Bool) {
        continueButton.setEnabled(enabled)
    }

    public func updateContinueButtonState() {
        let currentStep = viewModel.getCurrentStep()
        let canProceed = canContinue(currentStep: currentStep)
        setContinueButtonEnabled(canProceed)
    }

    /// Call this method when content height changes (e.g., when showing/hiding category buttons)
    public func notifyContentHeightChanged() {
        updateContentHeight()
        updateSheetHeight()
    }
    
    private func showViewController(at index: Int) {
        guard index < viewControllers.count else {
            return
        }

        // Remove current child VC
        if let currentVC = currentChildVC {
            currentVC.willMove(toParent: nil)
            currentVC.view.removeFromSuperview()
            currentVC.removeFromParent()
        }
        
        // Add new child VC
        let newVC = viewControllers[index]
        addChild(newVC)
        
        // Load the view if it hasn't been loaded yet
        newVC.loadViewIfNeeded()
        
        contentContainerView.addSubview(newVC.view)
        
        // Use Auto Layout instead of frame
        newVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newVC.view.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            newVC.view.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            newVC.view.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            newVC.view.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor)
        ])
        
        newVC.didMove(toParent: self)

        currentChildVC = newVC

        // Update content height constraint based on child VC
        updateContentHeight()

        // Update sheet height when child VC changes
        updateSheetHeight()
    }

    private func updateContentHeight() {
        guard let childVC = currentChildVC as? AddPlanChildViewController else { return }
        contentHeightConstraint?.constant = childVC.preferredContentHeight
        view.layoutIfNeeded()
    }

    // MARK: - Actions
    @objc private func backButtonTapped() {
        viewModel.backStepAction()
    }
    
    @objc private func closeButtonTapped() {
        delegate?.addPlanContainerDidCancel(self)
        dismiss(animated: true)
    }

    @objc private func clearSelectionTapped() {
        // Notify current step to clear
        if let currentVC = currentChildVC as? AddPlanSelectDayVC {
            currentVC.clearSelection()
        } else if let currentVC = currentChildVC as? AddPlanTimeAndTravelersVC {
            currentVC.clearSelection()
        } else if let currentVC = currentChildVC as? AddPlanCategorySelectionVC {
            currentVC.clearSelection()
        }
        
        // Update continue button state after clearing
        updateContinueButtonState()
    }
    
    @objc private func continueButtonTapped() {
        // Validate current step before continuing
        let currentStep = viewModel.getCurrentStep()

        if canContinue(currentStep: currentStep) {
            // Check if manual mode with specific category selected
            if currentStep == .selectDayAndCity &&
               viewModel.planData.selectedMode == .manual {

                if let selectedCategory = viewModel.planData.selectedCategories.first {
                    switch selectedCategory {
                    case "activities":
                        // Show activity listing screen
                        delegate?.addPlanContainerShouldShowActivityListing(self, data: viewModel.planData)
                        return
                    case "places_of_interest":
                        // Show POI listing screen for places of interest
                        delegate?.addPlanContainerShouldShowPOIListing(self, data: viewModel.planData, categoryType: .placesOfInterest)
                        return
                    case "eat_and_drink":
                        // Show POI listing screen for eat and drink
                        delegate?.addPlanContainerShouldShowPOIListing(self, data: viewModel.planData, categoryType: .eatAndDrink)
                        return
                    default:
                        break
                    }
                }
            }

            viewModel.goNextStep()
        }
    }
    
    private func canContinue(currentStep: AddPlanSteps) -> Bool {
        switch currentStep {
        case .selectDayAndCity:
            let hasDayAndCity = viewModel.planData.selectedDay != nil && 
                               viewModel.planData.selectedCity != nil &&
                               viewModel.planData.selectedMode != .none
            // If manual mode, also require category selection
            if viewModel.planData.selectedMode == .manual {
                return hasDayAndCity && !viewModel.planData.selectedCategories.isEmpty
            }
            return hasDayAndCity
        case .timeAndTravelers:
            guard let startTime = viewModel.planData.startTime,
                  let endTime = viewModel.planData.endTime else {
                return false
            }
            // End time must be greater than start time
            return viewModel.planData.startingPointLocation != nil &&
                   endTime > startTime &&
                   viewModel.planData.travelers > 0
        case .categorySelection:
            return !viewModel.planData.selectedCategories.isEmpty
        }
    }
    
    private func updateUI() {
        let currentStep = viewModel.getCurrentStep()
        
        // Update title
        titleLabel.text = currentStep.getTitle()
        
        // Update back button visibility
        backButton.isHidden = (currentStep.getPreviousStep() == nil)
        
        // Update clear selection button visibility - stack view will handle layout automatically
        let isFirstScreen = (currentStep == .selectDayAndCity)
        clearSelectionButton.isHidden = isFirstScreen
        
        // Update continue button title
        continueButton.updateTitle(viewModel.getButtonTitle())
        
        // Update continue button state based on current step validation
        let canProceed = canContinue(currentStep: currentStep)
        setContinueButtonEnabled(canProceed)
        
        // Show appropriate view controller
        showViewController(at: currentStep.getIndex())
    }
}

// MARK: - AddPlanContainerViewModelDelegate
extension AddPlanContainerVC: AddPlanContainerViewModelDelegate {
    public func stepChanged() {
        updateUI()
    }
    
    public func planCompleted(data: AddPlanData) {
        delegate?.addPlanContainerDidComplete(self, data: data)
        dismiss(animated: true)
    }
}
