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
}

@objc(SPMAddPlanContainerVC)
public class AddPlanContainerVC: TRPBaseUIViewController {
    
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
    
    // MARK: - Content Container
    private let contentContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()
    
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
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            // Back Button
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 24),
            backButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Title
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -8),
            
            // Close Button
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 18),
            closeButton.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    private func setupContentContainer() {
        view.addSubview(contentContainerView)

        NSLayoutConstraint.activate([
            contentContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            contentContainerView.bottomAnchor.constraint(equalTo: footerView.topAnchor)
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
            footerView.heightAnchor.constraint(equalToConstant: 80),

            // Stack View
            buttonStackView.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),
            buttonStackView.centerYAnchor.constraint(equalTo: footerView.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        clearSelectionButton.addTarget(self, action: #selector(clearSelectionTapped), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
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
    
    private func showViewController(at index: Int) {
        guard index < viewControllers.count else {
            print("⚠️ No VC at index \(index), total VCs: \(viewControllers.count)")
            return
        }
        
        print("📱 Showing VC at index \(index)")
        
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
            // Check if manual mode with activities category selected
            if currentStep == .selectDayAndCity &&
               viewModel.planData.selectedMode == .manual &&
               viewModel.planData.selectedCategories.first == "activities" {
                // Show activity listing screen instead of next step
                delegate?.addPlanContainerShouldShowActivityListing(self, data: viewModel.planData)
                return
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
            return viewModel.planData.startingPointLocation != nil &&
                   viewModel.planData.startTime != nil &&
                   viewModel.planData.endTime != nil &&
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
        print("✅ Plan completed!")
        delegate?.addPlanContainerDidComplete(self, data: data)
        dismiss(animated: true)
    }
}
